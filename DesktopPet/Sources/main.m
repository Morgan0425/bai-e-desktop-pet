#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <Carbon/Carbon.h>

typedef NS_ENUM(NSInteger, PetMode) { PetModeIdle, PetModeHover, PetModeDragging, PetModeReacting, PetModeSleeping, PetModeSitting, PetModeAngry };

@interface PetView : NSView
@property NSImageView *front; @property NSImageView *back; @property NSImage *closedEyesFrame; @property NSArray<NSImage *> *eatFrames; @property NSArray<NSImage *> *sleepFrames; @property NSArray<NSImage *> *raisedFrames; @property NSArray<NSImage *> *sitFrames; @property NSArray<NSImage *> *angerFrames; @property NSArray<NSImage *> *idleFrames; @property NSArray<NSImage *> *questionFrames; @property NSArray<NSImage *> *shyFrames;
@property PetMode mode; @property NSPoint dragOrigin;
@property BOOL didMove; @property BOOL hovering; @property BOOL showingShy; @property BOOL showingClosedEyes; @property BOOL suppressMouseUp; @property BOOL dragLiftCompleted; @property NSTrackingArea *trackingArea;
@property NSDate *lastInteraction; @property NSDate *nextIdleChange; @property NSDate *angerUntil;
@property NSTimeInterval lastClickTime; @property NSInteger rapidClickCount; @property NSUInteger actionToken; @property NSUInteger dragMotionSerial;
- (void)eatAction; - (void)sleepAction; - (void)sitAction;
@end

@implementation PetView
- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.wantsLayer = YES; self.mode = PetModeIdle;
        self.lastInteraction = [NSDate date]; self.nextIdleChange = [NSDate dateWithTimeIntervalSinceNow:7.0];
        self.back = [[NSImageView alloc] initWithFrame:self.bounds]; self.front = [[NSImageView alloc] initWithFrame:self.bounds];
        for (NSImageView *view in @[self.back, self.front]) { view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable; view.imageScaling = NSImageScaleProportionallyUpOrDown; [self addSubview:view]; }
        NSURL *root = NSBundle.mainBundle.resourceURL;
        self.closedEyesFrame = [[NSImage alloc] initWithContentsOfURL:[root URLByAppendingPathComponent:@"Frames/closed_eyes.png"]];
        NSMutableArray *eating = [NSMutableArray array];
        for (NSInteger i = 1; i <= 16; i++) { NSString *name = [NSString stringWithFormat:@"Animations/Eat/frame_%02ld.png", (long)i]; NSImage *image = [[NSImage alloc] initWithContentsOfURL:[root URLByAppendingPathComponent:name]]; if (image) [eating addObject:image]; }
        self.eatFrames = eating;
        NSMutableArray *sleeping = [NSMutableArray array];
        for (NSInteger i = 1; i <= 16; i++) { NSString *name = [NSString stringWithFormat:@"Animations/Sleep/frame_%02ld.png", (long)i]; NSImage *image = [[NSImage alloc] initWithContentsOfURL:[root URLByAppendingPathComponent:name]]; if (image) [sleeping addObject:image]; }
        self.sleepFrames = sleeping;
        NSMutableArray *raised = [NSMutableArray array];
        for (NSInteger i = 1; i <= 16; i++) { NSString *name = [NSString stringWithFormat:@"Animations/Raised/frame_%02ld.png", (long)i]; NSImage *image = [[NSImage alloc] initWithContentsOfURL:[root URLByAppendingPathComponent:name]]; if (image) [raised addObject:image]; }
        self.raisedFrames = raised;
        NSMutableArray *sitting = [NSMutableArray array];
        for (NSInteger i = 1; i <= 16; i++) { NSString *name = [NSString stringWithFormat:@"Animations/Sit/frame_%02ld.png", (long)i]; NSImage *image = [[NSImage alloc] initWithContentsOfURL:[root URLByAppendingPathComponent:name]]; if (image) [sitting addObject:image]; }
        self.sitFrames = sitting;
        NSMutableArray *angry = [NSMutableArray array];
        for (NSInteger i = 1; i <= 16; i++) { NSString *name = [NSString stringWithFormat:@"Animations/Anger/frame_%02ld.png", (long)i]; NSImage *image = [[NSImage alloc] initWithContentsOfURL:[root URLByAppendingPathComponent:name]]; if (image) [angry addObject:image]; }
        self.angerFrames = angry;
        NSMutableArray *idle = [NSMutableArray array];
        for (NSInteger i = 1; i <= 16; i++) { NSString *name = [NSString stringWithFormat:@"Animations/Idle/frame_%02ld.png", (long)i]; NSImage *image = [[NSImage alloc] initWithContentsOfURL:[root URLByAppendingPathComponent:name]]; if (image) [idle addObject:image]; }
        self.idleFrames = idle;
        NSMutableArray *question = [NSMutableArray array];
        for (NSInteger i = 1; i <= 16; i++) { NSString *name = [NSString stringWithFormat:@"Animations/Question/frame_%02ld.png", (long)i]; NSImage *image = [[NSImage alloc] initWithContentsOfURL:[root URLByAppendingPathComponent:name]]; if (image) [question addObject:image]; }
        self.questionFrames = question;
        NSMutableArray *shy = [NSMutableArray array];
        for (NSInteger i = 1; i <= 16; i++) { NSString *name = [NSString stringWithFormat:@"Animations/Shy/frame_%02ld.png", (long)i]; NSImage *image = [[NSImage alloc] initWithContentsOfURL:[root URLByAppendingPathComponent:name]]; if (image) [shy addObject:image]; }
        self.shyFrames = shy; self.front.image = self.idleFrames.firstObject ?: self.closedEyesFrame; self.back.alphaValue = 0;
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(idleTick) userInfo:nil repeats:YES];
        [self beginIdleLoop];
    } return self;
}
- (void)updateTrackingAreas { [super updateTrackingAreas]; if (self.trackingArea) [self removeTrackingArea:self.trackingArea]; self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingInVisibleRect owner:self userInfo:nil]; [self addTrackingArea:self.trackingArea]; }
- (void)touchActivity { self.lastInteraction = [NSDate date]; self.nextIdleChange = [NSDate dateWithTimeIntervalSinceNow:6.0 + arc4random_uniform(6)]; }
- (void)showClosedEyes { if (!self.closedEyesFrame) return; self.showingClosedEyes = YES; self.front.image = self.closedEyesFrame; self.front.alphaValue = 1; self.back.alphaValue = 0; }
- (void)showEatFrame:(NSInteger)next { if (next < 0 || next >= self.eatFrames.count) return; self.front.image = self.eatFrames[next]; self.front.alphaValue = 1; self.back.alphaValue = 0; }
- (void)showIdleFrame:(NSInteger)next { if (next < 0 || next >= self.idleFrames.count) return; self.front.image = self.idleFrames[next]; self.front.alphaValue = 1; self.back.alphaValue = 0; }
- (void)showQuestionFrame:(NSInteger)next { if (next < 0 || next >= self.questionFrames.count) return; self.front.image = self.questionFrames[next]; self.front.alphaValue = 1; self.back.alphaValue = 0; }
- (void)showShyFrame:(NSInteger)next { if (next < 0 || next >= self.shyFrames.count) return; self.front.image = self.shyFrames[next]; self.front.alphaValue = 1; self.back.alphaValue = 0; }
- (void)runQuestionLoopStep:(NSInteger)stepIndex token:(NSUInteger)token {
    if (self.actionToken != token || self.mode != PetModeHover || !self.hovering || self.showingShy) return;
    [self showQuestionFrame:4 + (stepIndex % 8)];
    [self after:0.22 token:token run:^{ [self runQuestionLoopStep:stepIndex + 1 token:token]; }];
}
- (void)runShyLoopStep:(NSInteger)stepIndex token:(NSUInteger)token {
    if (self.actionToken != token || self.mode != PetModeHover || !self.hovering || !self.showingShy) return;
    [self showShyFrame:4 + (stepIndex % 8)];
    [self after:0.23 token:token run:^{ [self runShyLoopStep:stepIndex + 1 token:token]; }];
}
- (void)beginShySequence {
    if (!self.hovering || self.mode != PetModeHover) return;
    self.showingShy = YES; NSUInteger token = ++self.actionToken;
    if (self.shyFrames.count != 16) { [self beginIdleLoop]; return; }
    NSTimeInterval step = 0.15;
    for (NSInteger i = 0; i < 4; i++) { [self after:i * step token:token run:^{ if (self.hovering && self.showingShy) [self showShyFrame:i]; }]; }
    [self after:4 * step token:token run:^{ [self runShyLoopStep:0 token:token]; }];
}
- (void)beginQuestionSequence {
    self.mode = PetModeHover; self.showingShy = NO; NSUInteger token = ++self.actionToken;
    if (self.questionFrames.count != 16) [self beginIdleLoop];
    else {
        NSTimeInterval step = 0.15;
        for (NSInteger i = 0; i < 4; i++) { [self after:i * step token:token run:^{ if (self.hovering && !self.showingShy) [self showQuestionFrame:i]; }]; }
        [self after:4 * step token:token run:^{ [self runQuestionLoopStep:0 token:token]; }];
    }
    [self after:3.5 token:token run:^{
        if (self.hovering && self.mode == PetModeHover && arc4random_uniform(100) < 55) [self beginShySequence];
    }];
}
- (void)endHoverSequence {
    BOOL wasShy = self.showingShy; NSArray<NSImage *> *sequence = wasShy ? self.shyFrames : self.questionFrames;
    self.mode = PetModeReacting; NSUInteger token = ++self.actionToken;
    if (sequence.count != 16) { [self beginIdleLoop]; return; }
    NSTimeInterval step = 0.15;
    for (NSInteger i = 0; i < 4; i++) { [self after:i * step token:token run:^{
        self.front.image = sequence[12 + i]; self.front.alphaValue = 1; self.back.alphaValue = 0;
    }]; }
    [self after:4 * step + 0.10 token:token run:^{ self.showingShy = NO; [self beginIdleLoop]; }];
}
- (void)runIdleLoopStep:(NSInteger)stepIndex token:(NSUInteger)token {
    if (self.actionToken != token || self.mode != PetModeIdle || self.idleFrames.count != 16) return;
    NSInteger frame = stepIndex % 16; [self showIdleFrame:frame];
    NSTimeInterval duration = (frame >= 5 && frame <= 7) ? 0.115 : 0.25;
    [self after:duration token:token run:^{ [self runIdleLoopStep:stepIndex + 1 token:token]; }];
}
- (void)beginIdleLoop {
    self.mode = PetModeIdle; self.showingClosedEyes = NO; NSUInteger token = ++self.actionToken;
    if (self.idleFrames.count == 16) [self runIdleLoopStep:0 token:token];
    else [self showClosedEyes];
}
- (void)playEatSequence {
    if (self.eatFrames.count != 16) { [self beginIdleLoop]; return; }
    self.mode = PetModeReacting; NSUInteger token = ++self.actionToken;
    // A: 1–4 once, B: 5–12 twice, C: 13–16 once.
    NSArray<NSNumber *> *order = @[@0,@1,@2,@3,@4,@5,@6,@7,@8,@9,@10,@11,@4,@5,@6,@7,@8,@9,@10,@11,@12,@13,@14,@15];
    NSTimeInterval step = 0.20;
    for (NSInteger i = 0; i < order.count; i++) { [self after:i * step token:token run:^{ [self showEatFrame:order[i].integerValue]; }]; }
    [self after:order.count * step + 0.25 token:token run:^{ [self returnToContext]; }];
}
- (void)showSleepFrame:(NSInteger)next { if (next < 0 || next >= self.sleepFrames.count) return; self.front.image = self.sleepFrames[next]; self.front.alphaValue = 1; self.back.alphaValue = 0; }
- (void)showSitFrame:(NSInteger)next { if (next < 0 || next >= self.sitFrames.count) return; self.front.image = self.sitFrames[next]; self.front.alphaValue = 1; self.back.alphaValue = 0; }
- (void)showAngerFrame:(NSInteger)next { if (next < 0 || next >= self.angerFrames.count) return; self.front.image = self.angerFrames[next]; self.front.alphaValue = 1; self.back.alphaValue = 0; }
- (void)endAngerSequence {
    if (self.mode != PetModeAngry) return;
    self.rapidClickCount = 0; self.mode = PetModeReacting; NSUInteger token = ++self.actionToken;
    if (self.angerFrames.count != 16) { [self returnToContext]; return; }
    NSTimeInterval step = 0.16;
    for (NSInteger i = 0; i < 4; i++) { [self after:i * step token:token run:^{ [self showAngerFrame:12 + i]; }]; }
    [self after:4 * step + 0.12 token:token run:^{ [self returnToContext]; }];
}
- (void)runAngerLoopStep:(NSInteger)stepIndex token:(NSUInteger)token {
    if (self.actionToken != token || self.mode != PetModeAngry) return;
    if ([self.angerUntil timeIntervalSinceNow] <= 0) { [self endAngerSequence]; return; }
    if (self.angerFrames.count == 16) [self showAngerFrame:4 + (stepIndex % 8)];
    else [self beginIdleLoop];
    [self after:0.20 token:token run:^{ [self runAngerLoopStep:stepIndex + 1 token:token]; }];
}
- (void)beginAngerSequence {
    self.angerUntil = [NSDate dateWithTimeIntervalSinceNow:1.8]; self.mode = PetModeAngry; NSUInteger token = ++self.actionToken;
    if (self.angerFrames.count != 16) { [self beginIdleLoop]; return; }
    NSTimeInterval step = 0.13;
    for (NSInteger i = 0; i < 4; i++) { [self after:i * step token:token run:^{ if (self.mode == PetModeAngry) [self showAngerFrame:i]; }]; }
    [self after:4 * step token:token run:^{ [self runAngerLoopStep:0 token:token]; }];
}
- (void)refreshAnger {
    self.angerUntil = [NSDate dateWithTimeIntervalSinceNow:1.8];
    if (self.mode != PetModeAngry) [self beginAngerSequence];
}
- (void)beginSitSequence {
    if (self.sitFrames.count != 16) { [self beginIdleLoop]; return; }
    self.mode = PetModeSitting; NSUInteger token = ++self.actionToken; NSTimeInterval step = 0.17;
    for (NSInteger i = 0; i < 5; i++) { [self after:i * step token:token run:^{ [self showSitFrame:i]; }]; }
}
- (void)endSitSequence {
    if (self.mode != PetModeSitting) return;
    if (self.sitFrames.count != 16) { self.actionToken++; [self returnToContext]; return; }
    self.mode = PetModeReacting; NSUInteger token = ++self.actionToken; NSTimeInterval step = 0.17;
    for (NSInteger i = 0; i < 4; i++) { [self after:i * step token:token run:^{ [self showSitFrame:12 + i]; }]; }
    [self after:4 * step + 0.12 token:token run:^{ [self returnToContext]; }];
}
- (void)showRaisedFrame:(NSInteger)next { if (next < 0 || next >= self.raisedFrames.count) return; self.front.image = self.raisedFrames[next]; self.front.alphaValue = 1; self.back.alphaValue = 0; }
- (void)beginRaisedDragSequence {
    self.mode = PetModeDragging; self.dragLiftCompleted = NO; self.dragMotionSerial++; NSUInteger token = ++self.actionToken;
    if (self.raisedFrames.count != 16) { [self beginIdleLoop]; return; }
    // Frames 1–4: grasp anticipation and lift-off. A still mouse then
    // holds frame 8; the other hanging poses are driven by horizontal input.
    NSTimeInterval step = 0.11;
    for (NSInteger i = 0; i < 4; i++) { [self after:i * step token:token run:^{ if (self.mode == PetModeDragging) [self showRaisedFrame:i]; }]; }
    [self after:4 * step token:token run:^{ if (self.mode == PetModeDragging) { self.dragLiftCompleted = YES; [self showRaisedFrame:7]; } }];
}
- (void)updateRaisedPoseForHorizontalDelta:(CGFloat)dx {
    if (!self.dragLiftCompleted || self.raisedFrames.count != 16) return;
    NSInteger pose = 7; // Frame 8 is the stable, centered hanging pose.
    CGFloat magnitude = fabs(dx);
    // The body trails behind the moving grab point, like a small pendulum.
    if (dx > 0.2) pose = magnitude > 7.0 ? 6 : 5;
    else if (dx < -0.2) pose = magnitude > 7.0 ? 9 : 8;
    [self showRaisedFrame:pose];
    NSUInteger serial = ++self.dragMotionSerial; NSUInteger token = self.actionToken;
    [self after:0.12 token:token run:^{
        if (self.mode == PetModeDragging && self.dragMotionSerial == serial) [self showRaisedFrame:7];
    }];
}
- (void)runSleepLoopWithToken:(NSUInteger)token {
    if (self.actionToken != token || self.mode != PetModeSleeping) return;
    NSTimeInterval step = 0.24;
    for (NSInteger i = 0; i < 8; i++) { [self after:i * step token:token run:^{ if (self.mode == PetModeSleeping) [self showSleepFrame:4 + i]; }]; }
    [self after:8 * step token:token run:^{ [self runSleepLoopWithToken:token]; }];
}
- (void)beginSleepSequence {
    if (self.sleepFrames.count != 16) { [self showClosedEyes]; return; }
    self.mode = PetModeSleeping; NSUInteger token = ++self.actionToken; NSTimeInterval step = 0.24;
    for (NSInteger i = 0; i < 4; i++) { [self after:i * step token:token run:^{ [self showSleepFrame:i]; }]; }
    [self after:4 * step token:token run:^{ [self runSleepLoopWithToken:token]; }];
}
- (void)wakeFromSleep {
    if (self.mode != PetModeSleeping) return;
    if (self.sleepFrames.count != 16) { self.actionToken++; [self returnToContext]; return; }
    self.mode = PetModeReacting; NSUInteger token = ++self.actionToken; NSTimeInterval step = 0.24;
    for (NSInteger i = 0; i < 4; i++) { [self after:i * step token:token run:^{ [self showSleepFrame:12 + i]; }]; }
    [self after:4 * step + 0.15 token:token run:^{ [self returnToContext]; }];
}
- (void)after:(NSTimeInterval)delay token:(NSUInteger)token run:(void (^)(void))block { dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ if (self.actionToken == token) block(); }); }
- (void)returnToContext { if (self.hovering) [self beginQuestionSequence]; else [self beginIdleLoop]; }
- (void)bounce { NSRect original = self.frame, lifted = NSInsetRect(original, 7, 7); lifted.origin.y += 8; [NSAnimationContext runAnimationGroup:^(NSAnimationContext *c) { c.duration = 0.10; self.animator.frame = lifted; } completionHandler:^{ [NSAnimationContext runAnimationGroup:^(NSAnimationContext *c) { c.duration = 0.15; c.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]; self.animator.frame = original; } completionHandler:nil]; }]; }
- (void)animateSpriteViewsTo:(NSRect)frame duration:(NSTimeInterval)duration timing:(CAMediaTimingFunctionName)timing completion:(void (^)(void))completion {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *c) {
        c.duration = duration; c.timingFunction = [CAMediaTimingFunction functionWithName:timing];
        self.front.animator.frame = frame; self.back.animator.frame = frame;
    } completionHandler:completion];
}
- (void)liftForDrag {
    NSRect lifted = self.bounds; lifted.origin.y += 8;
    [self animateSpriteViewsTo:lifted duration:0.10 timing:kCAMediaTimingFunctionEaseOut completion:nil];
}
- (void)landAfterDrag {
    self.mode = PetModeReacting; self.dragLiftCompleted = NO; self.dragMotionSerial++; NSUInteger token = ++self.actionToken;
    if (self.raisedFrames.count == 16) {
        // Frames 11–16: release, fall, impact, rebound, and return to standing.
        NSTimeInterval step = 0.13;
        NSRect falling = self.bounds; falling.origin.y -= 12;
        [self animateSpriteViewsTo:falling duration:step * 2.7 timing:kCAMediaTimingFunctionEaseIn completion:nil];
        for (NSInteger i = 0; i < 6; i++) { [self after:i * step token:token run:^{ [self showRaisedFrame:10 + i]; }]; }
        [self after:3 * step token:token run:^{
            NSRect impact = NSMakeRect(-3, -2, self.bounds.size.width + 6, self.bounds.size.height - 3);
            [self animateSpriteViewsTo:impact duration:0.09 timing:kCAMediaTimingFunctionEaseIn completion:nil];
        }];
        [self after:4 * step token:token run:^{ [self animateSpriteViewsTo:self.bounds duration:0.22 timing:kCAMediaTimingFunctionEaseOut completion:nil]; }];
        [self after:6 * step + 0.12 token:token run:^{ [self returnToContext]; }];
        return;
    }
    [self beginIdleLoop];
    NSRect landed = NSMakeRect(-4, -2, self.bounds.size.width + 8, self.bounds.size.height - 4);
    [self animateSpriteViewsTo:landed duration:0.10 timing:kCAMediaTimingFunctionEaseIn completion:^{
        if (self.actionToken != token) return;
        [self animateSpriteViewsTo:self.bounds duration:0.20 timing:kCAMediaTimingFunctionEaseOut completion:^{
            if (self.actionToken == token) [self returnToContext];
        }];
    }];
}
- (NSInteger)timeAwareIdleAction {
    NSInteger hour = [NSCalendar.currentCalendar component:NSCalendarUnitHour fromDate:[NSDate date]];
    uint32_t r = arc4random_uniform(100);
    // 0 = continuous idle, 1 = eat, 2 = sleep, 3 = sit,
    // 4 = the sole permitted static pose (closed eyes).
    if (hour >= 23 || hour < 7) return 2;
    if (hour >= 7 && hour < 9) return r < 55 ? 1 : 0;
    if (hour == 12) return r < 75 ? 1 : (r < 90 ? 3 : 0);
    if (hour == 13) return r < 50 ? 3 : (r < 82 ? 4 : 0);
    if (hour == 18) return r < 70 ? 1 : (r < 87 ? 3 : 0);
    if (hour == 22) return r < 55 ? 4 : (r < 80 ? 3 : 0);
    return r < 72 ? 0 : (r < 86 ? 3 : 1);
}
- (void)idleTick {
    if (self.mode == PetModeDragging || self.mode == PetModeReacting || self.mode == PetModeSleeping || self.mode == PetModeSitting || self.mode == PetModeAngry) return;
    NSTimeInterval quiet = -self.lastInteraction.timeIntervalSinceNow;
    if (quiet >= 120.0) { [self beginSleepSequence]; return; }
    if (quiet >= 30.0) { if (!self.showingClosedEyes) { self.actionToken++; self.mode = PetModeIdle; [self showClosedEyes]; } return; }
    if ([self.nextIdleChange timeIntervalSinceNow] > 0) return;
    NSInteger next = [self timeAwareIdleAction];
    if (next == 1) [self playEatSequence];
    else if (next == 2) [self beginSleepSequence];
    else if (next == 3) { [self beginSitSequence]; NSUInteger token = self.actionToken; [self after:4.5 token:token run:^{ [self endSitSequence]; }]; }
    else if (next == 4) { self.actionToken++; self.mode = PetModeIdle; [self showClosedEyes]; }
    self.nextIdleChange = [NSDate dateWithTimeIntervalSinceNow:6.0 + arc4random_uniform(6)];
}
- (void)mouseEntered:(NSEvent *)event {
    self.hovering = YES; [self touchActivity]; if (self.mode == PetModeSleeping) { [self wakeFromSleep]; return; } if (self.mode == PetModeDragging || self.mode == PetModeReacting || self.mode == PetModeSitting || self.mode == PetModeAngry) return;
    [self beginQuestionSequence];
}
- (void)mouseExited:(NSEvent *)event { self.hovering = NO; [self touchActivity]; if (self.mode == PetModeDragging || self.mode == PetModeReacting || self.mode == PetModeSitting || self.mode == PetModeAngry) return; if (self.mode == PetModeHover) [self endHoverSequence]; else [self beginIdleLoop]; }
- (void)mouseDown:(NSEvent *)event {
    [self touchActivity];
    if (self.mode == PetModeSleeping) { self.suppressMouseUp = YES; [self wakeFromSleep]; return; }
    if (self.mode == PetModeSitting) { self.suppressMouseUp = YES; [self endSitSequence]; return; }
    self.dragOrigin = NSEvent.mouseLocation; self.didMove = NO; self.dragLiftCompleted = NO; self.dragMotionSerial++;
    if (self.mode != PetModeAngry) self.actionToken++;
}
- (void)mouseDragged:(NSEvent *)event {
    if (self.suppressMouseUp) return;
    NSPoint current = NSEvent.mouseLocation; CGFloat dx = current.x - self.dragOrigin.x, dy = current.y - self.dragOrigin.y;
    if (!self.didMove && hypot(dx, dy) > 2.0) { self.didMove = YES; [self beginRaisedDragSequence]; }
    if (!self.didMove) return; NSPoint origin = self.window.frame.origin; origin.x += dx; origin.y += dy; [self.window setFrameOrigin:origin];
    [self updateRaisedPoseForHorizontalDelta:dx];
    self.dragOrigin = current; [self touchActivity];
}
- (void)handleSingleClick { [self returnToContext]; }
- (void)handleDoubleClick { [self returnToContext]; }
- (void)mouseUp:(NSEvent *)event {
    [self touchActivity];
    if (self.suppressMouseUp) { self.suppressMouseUp = NO; return; }
    if (self.didMove) { [self landAfterDrag]; return; }
    if (self.mode == PetModeAngry) { self.lastClickTime = event.timestamp; self.rapidClickCount = MAX(3, self.rapidClickCount); [self refreshAnger]; return; }
    NSTimeInterval now = event.timestamp; self.rapidClickCount = (now - self.lastClickTime < 0.55) ? self.rapidClickCount + 1 : 1; self.lastClickTime = now;
    if (self.rapidClickCount >= 3) { [self beginAngerSequence]; }
    else if (event.clickCount >= 2) { NSUInteger pending = ++self.actionToken; [self after:0.6 token:pending run:^{ [self handleDoubleClick]; }]; }
    else { NSUInteger pending = ++self.actionToken; [self after:0.27 token:pending run:^{ [self handleSingleClick]; }]; }
}
- (void)scrollWheel:(NSEvent *)event { [self touchActivity]; }
- (void)rightMouseDown:(NSEvent *)event {
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *hide = [[NSMenuItem alloc] initWithTitle:@"隐藏桌宠（⌃⌥H）" action:@selector(orderOut:) keyEquivalent:@""]; hide.target = self.window; [menu addItem:hide];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"退出桌宠（⌃⌥Q）" action:@selector(terminate:) keyEquivalent:@""]; quit.target = NSApp; [menu addItem:quit]; [NSMenu popUpContextMenu:menu withEvent:event forView:self];
}
- (void)eatAction { [self touchActivity]; if (self.mode != PetModeAngry) [self playEatSequence]; }
- (void)sleepAction { if (self.mode == PetModeAngry) return; self.lastInteraction = [NSDate dateWithTimeIntervalSinceNow:-120.0]; [self beginSleepSequence]; }
- (void)sitAction { [self touchActivity]; if (self.mode == PetModeAngry) return; if (self.mode == PetModeSitting) [self endSitSequence]; else [self beginSitSequence]; }
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property NSWindow *window; @property EventHotKeyRef quitHotKey; @property EventHotKeyRef hideHotKey;
- (void)togglePet;
@end

static OSStatus HotKeyHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData) { EventHotKeyID hotKeyID; GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hotKeyID), NULL, &hotKeyID); AppDelegate *delegate = (__bridge AppDelegate *)userData; if (hotKeyID.id == 1) [NSApp terminate:nil]; if (hotKeyID.id == 2) [delegate togglePet]; return noErr; }

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSSize size = NSMakeSize(330, 260); self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, size.width, size.height) styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    self.window.opaque = NO; self.window.backgroundColor = NSColor.clearColor; self.window.hasShadow = NO; self.window.level = NSFloatingWindowLevel; self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
    NSView *container = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, size.width, size.height)];
    PetView *pet = [[PetView alloc] initWithFrame:NSMakeRect(0, 0, 260, 260)]; [container addSubview:pet];
    NSArray *titles = @[@"🍙 吃饭", @"💤 睡觉", @"🪑 坐下"];
    NSArray *actions = @[@"eatAction", @"sleepAction", @"sitAction"];
    for (NSInteger i = 0; i < titles.count; i++) { NSButton *button = [NSButton buttonWithTitle:titles[i] target:pet action:NSSelectorFromString(actions[i])]; button.frame = NSMakeRect(264, 183 - i * 46, 64, 34); button.bezelStyle = NSBezelStyleRounded; button.font = [NSFont systemFontOfSize:11 weight:NSFontWeightMedium]; [container addSubview:button]; }
    self.window.contentView = container;
    NSScreen *screen = NSScreen.mainScreen; if (screen) { NSRect visible = screen.visibleFrame; [self.window setFrameOrigin:NSMakePoint(NSMaxX(visible) - size.width - 28, NSMinY(visible) + 28)]; } [self.window makeKeyAndOrderFront:nil];
    EventTypeSpec type = {kEventClassKeyboard, kEventHotKeyPressed}; InstallApplicationEventHandler(&HotKeyHandler, 1, &type, (__bridge void *)self, NULL);
    EventHotKeyID quitID = {'DPet', 1}, hideID = {'DPet', 2}; RegisterEventHotKey(kVK_ANSI_Q, controlKey | optionKey, quitID, GetApplicationEventTarget(), 0, &_quitHotKey); RegisterEventHotKey(kVK_ANSI_H, controlKey | optionKey, hideID, GetApplicationEventTarget(), 0, &_hideHotKey);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSUserNotification *note = [[NSUserNotification alloc] init]; note.title = @"白厄桌宠已启动"; note.informativeText = @"⌃⌥H 隐藏/显示 · ⌃⌥Q 随时退出"; [NSUserNotificationCenter.defaultUserNotificationCenter deliverNotification:note];
#pragma clang diagnostic pop
}
- (void)togglePet { if (self.window.visible) [self.window orderOut:nil]; else [self.window orderFrontRegardless]; }
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return YES; }
- (void)applicationWillTerminate:(NSNotification *)notification { if (self.quitHotKey) UnregisterEventHotKey(self.quitHotKey); if (self.hideHotKey) UnregisterEventHotKey(self.hideHotKey); }
@end

int main(int argc, const char *argv[]) { @autoreleasepool { NSApplication *app = NSApplication.sharedApplication; AppDelegate *delegate = [[AppDelegate alloc] init]; app.delegate = delegate; [app setActivationPolicy:NSApplicationActivationPolicyAccessory]; [app run]; } return 0; }
