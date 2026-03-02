#ifndef RUNNER_CHANNEL_HANDLER_H_
#define RUNNER_CHANNEL_HANDLER_H_

#include <flutter/binary_messenger.h>

// Sets up all MethodChannel handlers for Windows.
// Equivalent to AppDelegate.setupChannels() on macOS.
void SetupChannels(flutter::BinaryMessenger* messenger);

#endif  // RUNNER_CHANNEL_HANDLER_H_
