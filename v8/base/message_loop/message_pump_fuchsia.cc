// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/message_loop/message_pump_fuchsia.h"

#include <magenta/status.h>
#include <magenta/syscalls.h>

#include "base/logging.h"

namespace base {

MessagePumpFuchsia::FileDescriptorWatcher::FileDescriptorWatcher(
    const tracked_objects::Location& from_here)
    : created_from_location_(from_here) {
}

MessagePumpFuchsia::FileDescriptorWatcher::~FileDescriptorWatcher() {
  if (!StopWatchingFileDescriptor())
    NOTREACHED();
  if (io_)
    __mxio_release(io_);
  if (was_destroyed_) {
    DCHECK(!*was_destroyed_);
    *was_destroyed_ = true;
  }
}

bool MessagePumpFuchsia::FileDescriptorWatcher::StopWatchingFileDescriptor() {
  // If our pump is gone, or we do not have a wait operation active, then there
  // is nothing to do here.
  if (!weak_pump_ || handle_ == MX_HANDLE_INVALID)
    return true;

  int result = mx_port_cancel(weak_pump_->port_, handle_, wait_key());
  DLOG_IF(ERROR, result != MX_OK)
      << "mx_port_cancel(handle=" << handle_
      << ") failed: " << mx_status_get_string(result);
  handle_ = MX_HANDLE_INVALID;

  return result == MX_OK;
}

MessagePumpFuchsia::MessagePumpFuchsia()
    : keep_running_(true), weak_factory_(this) {
  CHECK_EQ(MX_OK, mx_port_create(0, &port_));
}

MessagePumpFuchsia::~MessagePumpFuchsia() {
  mx_status_t status = mx_handle_close(port_);
  if (status != MX_OK) {
    DLOG(ERROR) << "mx_handle_close failed: " << mx_status_get_string(status);
  }
}

bool MessagePumpFuchsia::WatchFileDescriptor(int fd,
                                             bool persistent,
                                             int mode,
                                             FileDescriptorWatcher* controller,
                                             Watcher* delegate) {
  DCHECK_GE(fd, 0);
  DCHECK(controller);
  DCHECK(delegate);

  controller->fd_ = fd;
  controller->persistent_ = persistent;
  controller->watcher_ = delegate;

  uint32_t events = 0;
  switch (mode) {
    case WATCH_READ:
      events = MXIO_EVT_READABLE;
      break;
    case WATCH_WRITE:
      events = MXIO_EVT_WRITABLE;
      break;
    case WATCH_READ_WRITE:
      events = MXIO_EVT_READABLE | MXIO_EVT_WRITABLE;
      break;
    default:
      NOTREACHED() << "unexpected mode: " << mode;
      return false;
  }
  controller->desired_events_ = events;

  controller->io_ = __mxio_fd_to_io(fd);
  if (!controller->io_) {
    DLOG(ERROR) << "Failed to get IO for FD";
    return false;
  }

  controller->weak_pump_ = weak_factory_.GetWeakPtr();

  return controller->WaitBegin();
}

bool MessagePumpFuchsia::FileDescriptorWatcher::WaitBegin() {
  uint32_t signals = 0u;
  __mxio_wait_begin(io_, desired_events_, &handle_, &signals);
  if (handle_ == MX_HANDLE_INVALID) {
    DLOG(ERROR) << "mxio_wait_begin failed";
    return false;
  }

  mx_status_t status = mx_object_wait_async(
      handle_, weak_pump_->port_, wait_key(), signals, MX_WAIT_ASYNC_ONCE);
  if (status != MX_OK) {
    DLOG(ERROR) << "mx_object_wait_async failed: "
                << mx_status_get_string(status)
                << " (port=" << weak_pump_->port_ << ")";
    return false;
  }
  return true;
}

uint32_t MessagePumpFuchsia::FileDescriptorWatcher::WaitEnd(uint32_t observed) {
  // Clear |handle_| so that StopWatchingFileDescriptor() is correctly treated
  // as a no-op. WaitBegin() will refresh |handle_| if the wait is persistent.
  handle_ = MX_HANDLE_INVALID;

  uint32_t events;
  __mxio_wait_end(io_, observed, &events);
  // |observed| can include other spurious things, in particular, that the fd
  // is writable, when we only asked to know when it was readable. In that
  // case, we don't want to call both the CanWrite and CanRead callback,
  // when the caller asked for only, for example, readable callbacks. So,
  // mask with the events that we actually wanted to know about.
  events &= desired_events_;
  return events;
}

void MessagePumpFuchsia::Run(Delegate* delegate) {
  DCHECK(keep_running_);

  for (;;) {
    bool did_work = delegate->DoWork();
    if (!keep_running_)
      break;

    did_work |= delegate->DoDelayedWork(&delayed_work_time_);
    if (!keep_running_)
      break;

    if (did_work)
      continue;

    did_work = delegate->DoIdleWork();
    if (!keep_running_)
      break;

    if (did_work)
      continue;

    mx_time_t deadline = delayed_work_time_.is_null()
                             ? MX_TIME_INFINITE
                             : delayed_work_time_.ToMXTime();
    mx_port_packet_t packet;

    const mx_status_t wait_status = mx_port_wait(port_, deadline, &packet, 0);
    if (wait_status != MX_OK && wait_status != MX_ERR_TIMED_OUT) {
      NOTREACHED() << "unexpected wait status: "
                   << mx_status_get_string(wait_status);
      continue;
    }

    if (packet.type == MX_PKT_TYPE_SIGNAL_ONE) {
      // A watched fd caused the wakeup via mx_object_wait_async().
      DCHECK_EQ(MX_OK, packet.status);
      FileDescriptorWatcher* controller =
          reinterpret_cast<FileDescriptorWatcher*>(
              static_cast<uintptr_t>(packet.key));

      DCHECK_NE(0u, packet.signal.trigger & packet.signal.observed);

      uint32_t events = controller->WaitEnd(packet.signal.observed);

      // Multiple callbacks may be called, must check controller destruction
      // after the first callback is run, which is done by letting the
      // destructor set a bool here (which is located on the stack). If it's set
      // during the first callback, then the controller was destroyed during the
      // first callback so we do not call the second one, as the controller
      // pointer is now invalid.
      bool controller_was_destroyed = false;
      controller->was_destroyed_ = &controller_was_destroyed;
      if (events & MXIO_EVT_WRITABLE)
        controller->watcher_->OnFileCanWriteWithoutBlocking(controller->fd_);
      if (!controller_was_destroyed && (events & MXIO_EVT_READABLE))
        controller->watcher_->OnFileCanReadWithoutBlocking(controller->fd_);
      if (!controller_was_destroyed) {
        controller->was_destroyed_ = nullptr;
        if (controller->persistent_)
          controller->WaitBegin();
      }
    } else {
      // Wakeup caused by ScheduleWork().
      DCHECK_EQ(MX_PKT_TYPE_USER, packet.type);
    }
  }

  keep_running_ = true;
}

void MessagePumpFuchsia::Quit() {
  keep_running_ = false;
}

void MessagePumpFuchsia::ScheduleWork() {
  // Since this can be called on any thread, we need to ensure that our Run loop
  // wakes up.
  mx_port_packet_t packet = {};
  packet.type = MX_PKT_TYPE_USER;
  mx_status_t status = mx_port_queue(port_, &packet, 0);
  DLOG_IF(ERROR, status != MX_OK)
      << "mx_port_queue failed: " << status << " (port=" << port_ << ")";
}

void MessagePumpFuchsia::ScheduleDelayedWork(
    const TimeTicks& delayed_work_time) {
  // We know that we can't be blocked right now since this method can only be
  // called on the same thread as Run, so we only need to update our record of
  // how long to sleep when we do sleep.
  delayed_work_time_ = delayed_work_time;
}

}  // namespace base
