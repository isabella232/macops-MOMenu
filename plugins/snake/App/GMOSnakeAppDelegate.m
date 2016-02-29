/// Copyright 2015 Google Inc. All rights reserved.
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///    http://www.apache.org/licenses/LICENSE-2.0
///
///    Unless required by applicable law or agreed to in writing, software
///    distributed under the License is distributed on an "AS IS" BASIS,
///    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///    See the License for the specific language governing permissions and
///    limitations under the License.

#import "GMOSnakeAppDelegate.h"

#import "GMOSnakeView.h"

@interface GMOSnakeAppDelegate ()
@property NSWindow *window;
@end

@implementation GMOSnakeAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 484, 705)
                                            styleMask:NSTitledWindowMask | NSClosableWindowMask
                                              backing:NSBackingStoreBuffered
                                                defer:NO];
  [self.window setTitle:@"MacOps Snake"];
  [self.window setReleasedWhenClosed:NO];

  NSImageView *background = [[NSImageView alloc] initWithFrame:NSMakeRect(-35, 0, 550, 705)];
  [background setImage:[[NSBundle mainBundle] imageForResource:@"background"]];
  [self.window.contentView addSubview:background];

  GMOSnakeView *snakeView = [[GMOSnakeView alloc] initWithFrame:NSMakeRect(88, 470, 307, 201)];
  [self.window.contentView addSubview:snakeView];

  [self.window center];
  [self.window makeKeyAndOrderFront:self];

  [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

@end
