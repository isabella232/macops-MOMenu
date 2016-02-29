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

#import "GMOSnakeView.h"

typedef enum direction { dLeft, dUp, dRight, dDown } direction;
typedef enum hitTestResult { htrEmpty, htrFood, htrWall, htrSnake } hitTestResult;

const double startingSpeed = 0.2f;
const double incTimeMultiplier = 0.98f;

const int fieldWidth = 24;
const int fieldHeight = 16;

const int initialLength = 6;

@interface GMOSnakeView () {
  NSSound *gameOver;
  NSSound *highScore;
  NSSound *eatMouse;

  NSTextField *scoreCounter;
  NSTextField *welcomeLabel;

  NSFont *pixelFont;
  NSColor *halfBlack;

  NSTimer *timerRedraw;
  NSTimer *timerGame;

  float gameSpeed;

  BOOL inGame;
  direction dir;
  direction nextDir;
  int score;
  int userHighScore;

  NSPoint snakePos;
  NSPoint foodPos;

  NSDictionary *foodPointOpts;
  NSMutableArray *snake;
}
@end

@implementation GMOSnakeView

- (instancetype)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    snake = [[NSMutableArray alloc] init];

    NSString *fontFilePath = [[NSBundle mainBundle] pathForResource:@"8bitwonder" ofType:@"ttf"];
    if (fontFilePath) {
      CTFontManagerRegisterFontsForURL((CFURLRef)[NSURL URLWithString:fontFilePath],
                                       kCTFontManagerScopeProcess,
                                       NULL);
    }
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    pixelFont = [fontManager fontWithFamily:@"8BIT WONDER"
                                     traits:NSUnboldFontMask
                                     weight:0
                                       size:12.0];

    halfBlack = [NSColor colorWithSRGBRed:0 green:0 blue:0 alpha:0.6];

    foodPointOpts = @{ NSForegroundColorAttributeName:halfBlack,
                                  NSFontAttributeName:[NSFont userFontOfSize:9.0] };

    timerRedraw = [NSTimer scheduledTimerWithTimeInterval:0.01f
                                                   target:self
                                                 selector:@selector(tickRedraw:)
                                                 userInfo:nil
                                                  repeats:YES];

    [self setScore:0 andGameOver:NO];

    gameOver = [self soundNamed:@"sound_gameover"];
    highScore = [self soundNamed:@"sound_highscore"];
    eatMouse = [self soundNamed:@"sound_score"];

    userHighScore = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"highscore"];
  }

  return self;
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
  NSView *frameView = [newWindow.contentView superview];
  NSRect windowframe = frameView.frame;
  scoreCounter = [[NSTextField alloc] initWithFrame:NSMakeRect(NSMaxX(windowframe)-160,
                                                               NSMaxY(windowframe)-20,
                                                               150,
                                                               18)];
  [scoreCounter setAlignment:NSRightTextAlignment];
  [scoreCounter setBezeled:NO];
  [scoreCounter setDrawsBackground:NO];
  [scoreCounter setEditable:NO];
  [scoreCounter setTextColor:halfBlack];
  [scoreCounter setSelectable:NO];
  [scoreCounter setStringValue:@""];

  // This causes a harmless stack trace on 10.10 because Apple thought it would be
  // smart to log this unsupported but working behavior and supply a half-assed
  // replacement in the form of NSTitlebarAccessoryViewController.
  [frameView addSubview:scoreCounter];

  welcomeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 307, 175)];
  [welcomeLabel setAlignment:NSCenterTextAlignment];
  [welcomeLabel setStringValue:(@"WELCOME TO\n"
                                "MACOPS SNAKE\n"
                                "\n"
                                "USE ARROW KEYS TO\n"
                                "CONTROL SNAKE\n"
                                "\n"
                                "PRESS ENTER\n"
                                "TO START\n"
                                "\n"
                                "\n"
                                "HAVE FUN")];
  [welcomeLabel setBezeled:NO];
  [welcomeLabel setDrawsBackground:NO];
  [welcomeLabel setEditable:NO];
  [welcomeLabel setFont:pixelFont];
  [welcomeLabel setTextColor:halfBlack];
  [welcomeLabel setHidden:NO];
  [self addSubview:welcomeLabel];
}

- (NSSound *)soundNamed:(NSString *)soundName {
  NSBundle *esBundle = [NSBundle mainBundle];
  return [[NSSound alloc] initWithContentsOfFile:[esBundle pathForSoundResource:soundName]
                                     byReference:NO];
}

- (void)setFood {
  NSPoint sp;

  foodPos.x = 0;
  foodPos.y = 0;

  do {
    sp.x = arc4random_uniform(fieldWidth - 2) + 1;
    sp.y = arc4random_uniform(fieldHeight - 2) + 1;
  } while ([self hitTestSnake:sp] != htrEmpty);

  foodPos = sp;
}

- (hitTestResult)hitTestSnake:(NSPoint)p {
  if ((p.x == -1) | (p.y == -1) | (p.x == fieldWidth) | (p.y == fieldHeight)) {
    return htrWall;
  }

  for (unsigned long i = 0; i < snake.count; i++) {
    NSPoint sp = [snake[i] pointValue];
    if ((sp.x == p.x) & (sp.y == p.y)) {
      return htrSnake;
    }
  }

  if ((foodPos.x == p.x) & (foodPos.y == p.y)) {
    return htrFood;
  }

  return htrEmpty;
}

- (void)keyDown:(NSEvent *)theEvent {
  if ([theEvent.characters isEqualTo:@"w"] && (theEvent.modifierFlags & NSCommandKeyMask)) {
    inGame = NO;
    [timerGame invalidate];
    [[[self superview] window] close];
  } else {
    [self interpretKeyEvents:@[ theEvent ]];
  }
}

- (IBAction)moveUp:(id)sender {
  if (dir != dUp && dir != dDown) nextDir = dUp;
}

- (IBAction)moveDown:(id)sender {
  if (dir != dDown && dir != dUp) nextDir = dDown;
}

- (IBAction)moveLeft:(id)sender {
  if (dir != dLeft && dir != dRight) nextDir = dLeft;
}


- (IBAction)moveRight:(id)sender {
  if (dir != dRight && dir != dLeft) nextDir = dRight;
}

- (IBAction)insertNewline:(id)sender {
  [self newGame:nil];
}

- (void)drawRect:(NSRect)dirtyRect {
  NSBezierPath *p;

  float cellWidth = self.bounds.size.width / fieldWidth;
  float cellHeight = self.bounds.size.height / fieldHeight;

  // Draw the snake body
  for (unsigned long i = 0; i < snake.count; i++) {
    [halfBlack set];
    NSPoint sp = [snake[i] pointValue];
    p = [NSBezierPath bezierPathWithRect:NSMakeRect(sp.x * cellWidth,
                                                    sp.y * cellHeight,
                                                    cellWidth - 1,
                                                    cellHeight - 1)];
    [p fill];
    [p stroke];
  }

  // Draw the food
  if (foodPos.x != -1 && foodPos.y != -1) {
    // The following lines don't line up, blame emoji.
    [@"🍎" drawInRect:NSMakeRect(foodPos.x * cellWidth,
                                 foodPos.y * cellHeight,
                                 cellWidth - 1,
                                 cellHeight - 1)
      withAttributes:foodPointOpts];
  }
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)tickRedraw:(id)sender {
  [self setNeedsDisplay:YES];
}

- (void)gameFailedHighScore:(BOOL)newHighScore {
  inGame = NO;

  [snake removeAllObjects];
  foodPos.x = -1;
  foodPos.y = -1;

  NSString *lblTxt = @"\n\nGAME OVER";
  if (newHighScore) {
    lblTxt = [lblTxt stringByAppendingFormat:@"\n\n\nHIGH SCORE: %d", score];
  } else {
    lblTxt = [lblTxt stringByAppendingFormat:@"\n\n\nSCORE: %d", score];
  }
  lblTxt = [lblTxt stringByAppendingString:@"\n\n\n\nPRESS ENTER TO PLAY AGAIN"];

  welcomeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 307, 175)];
  [welcomeLabel setAlignment:NSCenterTextAlignment];
  [welcomeLabel setBezeled:NO];
  [welcomeLabel setDrawsBackground:NO];
  [welcomeLabel setEditable:NO];
  [welcomeLabel setFont:pixelFont];
  [welcomeLabel setHidden:NO];
  [welcomeLabel setStringValue:lblTxt];
  [welcomeLabel setTextColor:halfBlack];
  [self addSubview:welcomeLabel];
}

- (void)tickGame:(id)sender {
  if (inGame) {
    dir = nextDir;

    switch (dir) {
      case dLeft: snakePos.x--; break;
      case dRight: snakePos.x++; break;
      case dUp: snakePos.y++; break;
      case dDown: snakePos.y--; break;
      default: break;
    }

    switch ([self hitTestSnake:snakePos]) {
      case htrEmpty:
        [snake insertObject:[NSValue valueWithPoint:snakePos] atIndex:0];
        [snake removeObjectAtIndex:[snake count] - 1];
        timerGame = [NSTimer scheduledTimerWithTimeInterval:gameSpeed
                                                     target:self
                                                   selector:@selector(tickGame:)
                                                   userInfo:nil
                                                    repeats:NO];
        break;

      case htrFood:
        [snake insertObject:[NSValue valueWithPoint:snakePos] atIndex:0];

        gameSpeed *= incTimeMultiplier;
        timerGame = [NSTimer scheduledTimerWithTimeInterval:gameSpeed
                                                     target:self
                                                   selector:@selector(tickGame:)
                                                   userInfo:nil
                                                    repeats:NO];
        [self setFood];
        [self setScore:(score + 1) andGameOver:NO];
        break;

      case htrSnake:
      case htrWall:
        [self setScore:score andGameOver:YES];
        break;
      default:
        break;
    }
  }
}

- (void)setScore:(int)value andGameOver:(BOOL)b {
  score = value;
  [scoreCounter setStringValue:[NSString stringWithFormat:@"Score: %d", score]];

  if (b) {
    if (score > userHighScore) {
      userHighScore = score;
      [[NSUserDefaults standardUserDefaults] setInteger:userHighScore forKey:@"highscore"];

      // Capture the current window, including frame.
      CGWindowID windowID = (CGWindowID)[self.window windowNumber];
      CGImageRef windowImage = CGWindowListCreateImage(
          CGRectNull, kCGWindowListOptionIncludingWindow, windowID, kCGWindowImageDefault);
      NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:windowImage];
      NSData *screenShot = [rep representationUsingType:NSPNGFileType properties:nil];
      [[NSUserDefaults standardUserDefaults] setObject:screenShot forKey:@"nagini"];

      [[NSUserDefaults standardUserDefaults] synchronize];

      [self gameFailedHighScore:YES];
      [highScore play];
    } else {
      [self gameFailedHighScore:NO];
      [gameOver play];
    }
  } else {
    if (score < 1) return;
    [eatMouse play];
  }
}

- (IBAction)newGame:(id)sender {
  if (!inGame) {
    [welcomeLabel removeFromSuperview];

    gameSpeed = startingSpeed;
    timerGame = [NSTimer scheduledTimerWithTimeInterval:gameSpeed
                                                 target:self
                                               selector:@selector(tickGame:)
                                               userInfo:nil
                                                repeats:NO];
    [snake removeAllObjects];

    snakePos.x = fieldWidth / 2;
    snakePos.y = fieldHeight / 2 - initialLength;

    for (int i = 0; i < initialLength; i++) {
      [snake insertObject:[NSValue valueWithPoint:snakePos] atIndex:0];
      if (i < (initialLength - 1)){
        snakePos.y++;
      }
    }

    dir = dUp;
    nextDir = dir;

    [self setFood];
    [self setScore:0 andGameOver:NO];

    inGame = YES;
  }
}

@end
