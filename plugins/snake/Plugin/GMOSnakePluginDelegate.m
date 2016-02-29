#import "GMOSnakePluginDelegate.h"

@implementation GMOSnakePluginDelegate

- (NSMenuItem *)menuItem {
  NSMenuItem *m = [[NSMenuItem alloc] initWithTitle:@"Snake..."
                                             action:@selector(openSnake:)
                                      keyEquivalent:@""];
  [m setTarget:self];
  return m;
}

- (IBAction)openSnake:(id)sender {
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *snakeApp = [bundle pathForResource:@"Snake" ofType:@"app"];
  [[NSWorkspace sharedWorkspace] launchApplication:snakeApp];
}

@end
