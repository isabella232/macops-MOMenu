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

#import "GCMAboutWindowController.h"

@interface GCMAboutWindowController ()
@property IBOutlet NSTextView *contentField;
@end

@implementation GCMAboutWindowController

- (void)windowDidLoad {
  [super windowDidLoad];
  NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"];
  NSData *displayData = [NSData dataWithContentsOfFile:htmlPath];
  NSAttributedString *displayString = [[NSAttributedString alloc] initWithHTML:displayData
                                                            documentAttributes:NULL];
  [[self.contentField textStorage] setAttributedString:displayString];
  [self setupMenu];
}

- (void)showWindow:(id)sender {
  [super showWindow:sender];
  [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)setupMenu {
  // Whilst the user will never see the menu, having one with the Copy, Select All, and Close
  // options allows the shortcuts for these items to work, which is useful for being able to copy
  // information from notifications. The mainMenu must have a nested menu for this to work properly.
  NSMenu *mainMenu = [[NSMenu alloc] init];
  NSMenu *editMenu = [[NSMenu alloc] init];
  [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
  [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
  [editMenu addItemWithTitle:@"Close" action:@selector(close) keyEquivalent:@"w"];
  NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
  [editMenuItem setSubmenu:editMenu];
  [mainMenu addItem:editMenuItem];
  [NSApp setMainMenu:mainMenu];
}

@end
