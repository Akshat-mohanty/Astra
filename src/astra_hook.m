#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

/* ─── Flipped View for clean top-down tab layout ─────────────────────────── */
@interface AstraFlippedView : NSView
@end
@implementation AstraFlippedView
- (BOOL)isFlipped { return YES; }
@end

/* ─── Astra Constellation Emblem View ─────────────────────────────────────── */
@interface AstraEmblemView : NSView
@end

@implementation AstraEmblemView
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSRect b = [self bounds];
    CGFloat w = b.size.width;
    CGFloat h = b.size.height;
    if (w <= 0 || h <= 0) return;

    CGContextRef ctx = [[NSGraphicsContext currentContext] CGContext];
    CGContextSaveGState(ctx);

    #define SX(x) ((x) / 24.0 * w)
    #define SY(y) (h - ((y) / 24.0 * h))

    // Outer diamond hexagon
    NSBezierPath *outer = [NSBezierPath bezierPath];
    [outer moveToPoint:NSMakePoint(SX(12.0), SY(2.0))];
    [outer lineToPoint:NSMakePoint(SX(20.5), SY(7.0))];
    [outer lineToPoint:NSMakePoint(SX(20.5), SY(17.0))];
    [outer lineToPoint:NSMakePoint(SX(12.0), SY(22.0))];
    [outer lineToPoint:NSMakePoint(SX(3.5), SY(17.0))];
    [outer lineToPoint:NSMakePoint(SX(3.5), SY(7.0))];
    [outer closePath];

    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.45] setStroke];
    [outer setLineWidth:1.2];
    [outer stroke];

    // Central Chevron A Core
    NSBezierPath *chevron = [NSBezierPath bezierPath];
    [chevron moveToPoint:NSMakePoint(SX(12.0), SY(6.8))];
    [chevron lineToPoint:NSMakePoint(SX(7.8), SY(14.8))];
    [chevron lineToPoint:NSMakePoint(SX(16.2), SY(14.8))];
    [chevron closePath];

    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.18] setFill];
    [chevron fill];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.92] setStroke];
    [chevron setLineWidth:1.5];
    [chevron stroke];

    CGContextRestoreGState(ctx);
    #undef SX
    #undef SY
}
@end

/* ─── Tab Title Sanitizer ────────────────────────────────────────────────── */
static NSString *AstraSanitizeTabTitle(NSString *st) {
    if (!st) return @"New Tab";
    st = [st stringByReplacingOccurrencesOfString:@"\u200B" withString:@""];
    st = [st stringByReplacingOccurrencesOfString:@"\u200C" withString:@""];
    st = [st stringByReplacingOccurrencesOfString:@"\u200D" withString:@""];
    st = [st stringByReplacingOccurrencesOfString:@"\uFEFF" withString:@""];
    st = [st stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([st length] == 0 || [st isEqualToString:@"about:blank"] || [st isEqualToString:@"chrome://newtab"]) {
        return @"New Tab";
    }
    return st;
}

/* ─── Tab Item Button ─────────────────────────────────────────────────────── */
@interface AstraTabButton : NSButton
@property (nonatomic, assign) NSInteger tabIndex;
@property (nonatomic, assign) BOOL isCurrent;
@property (nonatomic, strong) NSButton *closeBtn;
@property (nonatomic, strong) NSTrackingArea *trackingArea;
@property (nonatomic, assign) BOOL isHovered;
@property (nonatomic, copy) NSString *rawTitle;
@end

@implementation AstraTabButton
- (instancetype)initWithFrame:(NSRect)frameRect title:(NSString *)title index:(NSInteger)idx isCurrent:(BOOL)current {
    self = [super initWithFrame:frameRect];
    if (self) {
        _tabIndex = idx;
        _isCurrent = current;
        _rawTitle = [AstraSanitizeTabTitle(title) copy];

        [self setButtonType:NSButtonTypeMomentaryChange];
        [self setBordered:NO];
        [self setTitle:@""];
        [self setWantsLayer:YES];
        self.layer.cornerRadius = 8.0;

        // Close Button
        _closeBtn = [[NSButton alloc] initWithFrame:NSMakeRect(frameRect.size.width - 26, 8, 18, 18)];
        [_closeBtn setButtonType:NSButtonTypeMomentaryChange];
        [_closeBtn setBordered:NO];
        [_closeBtn setTitle:@"×"];
        [_closeBtn setFont:[NSFont systemFontOfSize:13 weight:NSFontWeightMedium]];
        [_closeBtn setWantsLayer:YES];
        _closeBtn.layer.cornerRadius = 4.0;
        [_closeBtn setAlphaValue:current ? 0.7 : 0.0];
        [self addSubview:_closeBtn];

        [self updateAppearance];
        [self setToolTip:_rawTitle];
    }
    return self;
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (_trackingArea) [self removeTrackingArea:_trackingArea];
    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)mouseEntered:(NSEvent *)event {
    _isHovered = YES;
    [_closeBtn setAlphaValue:0.8];
    [self updateAppearance];
}

- (void)mouseExited:(NSEvent *)event {
    _isHovered = NO;
    [_closeBtn setAlphaValue:_isCurrent ? 0.6 : 0.0];
    [self updateAppearance];
}

- (void)updateAppearance {
    if (_isCurrent) {
        self.layer.backgroundColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.12].CGColor;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.24].CGColor;
    } else if (_isHovered) {
        self.layer.backgroundColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.05].CGColor;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.1].CGColor;
    } else {
        self.layer.backgroundColor = [NSColor clearColor].CGColor;
        self.layer.borderWidth = 0.0;
    }
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    NSRect b = [self bounds];
    BOOL compact = (b.size.width < 100);

    // Title label
    NSString *t = AstraSanitizeTabTitle(_rawTitle);

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineBreakMode:NSLineBreakByTruncatingTail];

    if (compact) {
        [_closeBtn setHidden:YES];
        [style setAlignment:NSTextAlignmentCenter];

        NSString *disp = (t && [t length] > 0) ? [t substringToIndex:MIN((NSUInteger)2, [t length])] : @"";
        NSDictionary *attrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:12 weight:_isCurrent ? NSFontWeightBold : NSFontWeightMedium],
            NSForegroundColorAttributeName: _isCurrent ? [NSColor whiteColor] : [NSColor colorWithCalibratedWhite:0.7 alpha:1.0],
            NSParagraphStyleAttributeName: style
        };
        NSRect textRect = NSMakeRect(4, (b.size.height - 16) / 2.0, b.size.width - 8, 16);
        [disp drawInRect:textRect withAttributes:attrs];
        return;
    }

    [_closeBtn setHidden:NO];

    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:12.5 weight:_isCurrent ? NSFontWeightSemibold : NSFontWeightRegular],
        NSForegroundColorAttributeName: _isCurrent ? [NSColor whiteColor] : [NSColor colorWithCalibratedWhite:0.7 alpha:1.0],
        NSParagraphStyleAttributeName: style
    };

    NSRect textRect = NSMakeRect(12, (b.size.height - 16) / 2.0, b.size.width - 40, 16);
    [t drawInRect:textRect withAttributes:attrs];
}
@end

/* ─── Settings Footer Button ─────────────────────────────────────────────── */
@interface AstraSettingsButton : NSButton
@property (nonatomic, strong) NSTrackingArea *trackingArea;
@property (nonatomic, assign) BOOL isHovered;
@end

@implementation AstraSettingsButton
- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setButtonType:NSButtonTypeMomentaryChange];
        [self setBordered:NO];
        [self setTitle:@"Settings"];
        [self setFont:[NSFont systemFontOfSize:12.5 weight:NSFontWeightMedium]];
        [self setContentTintColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];
        [self setAlignment:NSTextAlignmentCenter];
        [self setWantsLayer:YES];
        self.layer.cornerRadius = 7.0;
    }
    return self;
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (_trackingArea) [self removeTrackingArea:_trackingArea];
    _trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                 options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)mouseEntered:(NSEvent *)event {
    _isHovered = YES;
    self.layer.backgroundColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.08].CGColor;
    [self setContentTintColor:[NSColor whiteColor]];
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)event {
    _isHovered = NO;
    self.layer.backgroundColor = [NSColor clearColor].CGColor;
    [self setContentTintColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];
    [self setNeedsDisplay:YES];
}
@end

/* ─── Astra Sidebar Collapse / Expand Button ──────────────────────────────── */
@interface AstraCollapseButton : NSButton
@property (nonatomic, strong) NSTrackingArea *trackingArea;
@property (nonatomic, assign) BOOL isHovered;
@property (nonatomic, assign) BOOL isCollapsed;
@property (nonatomic, assign) BOOL isFloating;
@end

@implementation AstraCollapseButton
- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setButtonType:NSButtonTypeMomentaryChange];
        [self setBordered:NO];
        [self setTitle:@""];
        [self setWantsLayer:YES];
        self.layer.cornerRadius = 6.0;
        _isCollapsed = NO;
        _isFloating = NO;
    }
    return self;
}

- (void)setIsFloating:(BOOL)floating {
    _isFloating = floating;
    if (_isFloating) {
        self.layer.cornerRadius = 7.0;
        self.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.12 green:0.12 blue:0.14 alpha:0.94].CGColor;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.16].CGColor;
    } else {
        self.layer.cornerRadius = 6.0;
        self.layer.backgroundColor = [NSColor clearColor].CGColor;
        self.layer.borderWidth = 0.0;
    }
    [self setNeedsDisplay:YES];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (_trackingArea) [self removeTrackingArea:_trackingArea];
    _trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                 options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)mouseEntered:(NSEvent *)event {
    _isHovered = YES;
    if (_isFloating) {
        self.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.18 green:0.18 blue:0.20 alpha:0.98].CGColor;
        self.layer.borderColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.3].CGColor;
    } else {
        self.layer.backgroundColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.1].CGColor;
    }
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)event {
    _isHovered = NO;
    if (_isFloating) {
        self.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.12 green:0.12 blue:0.14 alpha:0.94].CGColor;
        self.layer.borderColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.16].CGColor;
    } else {
        self.layer.backgroundColor = [NSColor clearColor].CGColor;
    }
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSRect b = [self bounds];
    CGFloat cx = b.size.width / 2.0;
    CGFloat cy = b.size.height / 2.0;

    NSColor *strokeColor = _isHovered ? [NSColor whiteColor] : [NSColor colorWithCalibratedWhite:0.75 alpha:1.0];
    [strokeColor setStroke];

    // Elegant sidebar outline rectangle
    CGFloat boxW = 15.0;
    CGFloat boxH = 13.0;
    NSRect boxRect = NSMakeRect(floor(cx - boxW / 2.0), floor(cy - boxH / 2.0), boxW, boxH);
    NSBezierPath *box = [NSBezierPath bezierPathWithRoundedRect:boxRect xRadius:2.5 yRadius:2.5];
    [box setLineWidth:1.2];
    [box stroke];

    // Vertical sidebar divider line
    CGFloat divX = boxRect.origin.x + 5.0;
    NSBezierPath *div = [NSBezierPath bezierPath];
    [div moveToPoint:NSMakePoint(divX, boxRect.origin.y + 0.5)];
    [div lineToPoint:NSMakePoint(divX, boxRect.origin.y + boxH - 0.5)];
    [div setLineWidth:1.1];
    [div stroke];

    // Miniature directional chevron arrow
    NSBezierPath *arr = [NSBezierPath bezierPath];
    [arr setLineWidth:1.3];
    [arr setLineCapStyle:NSLineCapStyleRound];
    [arr setLineJoinStyle:NSLineJoinStyleRound];

    if (_isCollapsed) {
        // Expand arrow pointing right: >
        CGFloat ax = cx + 2.8;
        [arr moveToPoint:NSMakePoint(ax - 1.5, cy + 2.5)];
        [arr lineToPoint:NSMakePoint(ax + 1.2, cy)];
        [arr lineToPoint:NSMakePoint(ax - 1.5, cy - 2.5)];
    } else {
        // Collapse arrow pointing left: <
        CGFloat ax = cx + 3.2;
        [arr moveToPoint:NSMakePoint(ax + 1.2, cy + 2.5)];
        [arr lineToPoint:NSMakePoint(ax - 1.5, cy)];
        [arr lineToPoint:NSMakePoint(ax + 1.2, cy - 2.5)];
    }
    [arr stroke];
}
@end

static void toggle_sidebar_collapse(void);
static void configure_window(NSWindow *win);

/* ─── Astra Vertical Sidebar View ─────────────────────────────────────────── */
@interface AstraVerticalSidebarView : NSView
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) AstraFlippedView *tabContainer;
@property (nonatomic, strong) NSView *footerView;
@property (nonatomic, strong) AstraSettingsButton *settingsBtn;
@property (nonatomic, strong) AstraCollapseButton *collapseBtn;
@property (nonatomic, strong) NSArray *lastTitles;
@property (nonatomic, assign) NSInteger lastActiveIndex;
- (void)layoutSidebarViews;
- (void)onCollapseClicked:(id)sender;
- (void)updateTabsWithTitles:(NSArray *)titles activeIndex:(NSInteger)activeIdx;
- (void)addOptimisticTabWithTitle:(NSString *)title;
- (void)removeActiveTabOptimistically;
- (void)setActiveTabIndexLocally:(NSInteger)idx;
- (void)removeTabLocallyAtIndex:(NSInteger)idx;
- (void)scrollToActiveTab;
@end

static __unsafe_unretained AstraVerticalSidebarView *s_currentSidebarView = nil;

static void query_and_update_tabs(AstraVerticalSidebarView *sidebarView) {
    if (!sidebarView || [sidebarView isHidden]) return;

    static BOOL s_is_querying = NO;
    if (s_is_querying) return;
    s_is_querying = YES;

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *src = @"tell application \"Astra\" to get {title of every tab of window 1, active tab index of window 1}";
        NSAppleScript *as = [[NSAppleScript alloc] initWithSource:src];
        NSDictionary *err = nil;
        NSAppleEventDescriptor *desc = [as executeAndReturnError:&err];

        if (!err && desc) {
            NSAppleEventDescriptor *titlesDesc = [desc descriptorAtIndex:1];
            NSAppleEventDescriptor *activeDesc = [desc descriptorAtIndex:2];
            NSInteger activeIdx = [activeDesc int32Value];
            NSMutableArray *titles = [NSMutableArray array];
            for (NSInteger i = 1; i <= [titlesDesc numberOfItems]; i++) {
                NSString *st = [[titlesDesc descriptorAtIndex:i] stringValue];
                [titles addObject:AstraSanitizeTabTitle(st)];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                s_is_querying = NO;
                if (sidebarView && ![sidebarView isHidden]) {
                    [sidebarView updateTabsWithTitles:titles activeIndex:activeIdx];
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                s_is_querying = NO;
            });
        }
    });
}

static void force_refresh_tabs(void) {
    if (s_currentSidebarView) {
        query_and_update_tabs(s_currentSidebarView);
    }
}

/* ─── Settings Helper & Menu Interceptor ──────────────────────────────────── */
static void open_settings_in_new_tab(void) {
    static NSTimeInterval s_last_open_settings = 0;
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (now - s_last_open_settings < 1.0) {
        return; // Prevent duplicate rapid invocation
    }
    s_last_open_settings = now;

    dispatch_async(dispatch_get_main_queue(), ^{
        // 1. Simulate Cmd+T (New tab in current window)
        CGKeyCode kc_t = 17; // 't'
        CGEventRef keyDown = CGEventCreateKeyboardEvent(NULL, kc_t, true);
        CGEventSetFlags(keyDown, kCGEventFlagMaskCommand);
        CGEventRef keyUp = CGEventCreateKeyboardEvent(NULL, kc_t, false);
        CGEventSetFlags(keyUp, kCGEventFlagMaskCommand);
        CGEventPost(kCGHIDEventTap, keyDown);
        CGEventPost(kCGHIDEventTap, keyUp);
        CFRelease(keyDown);
        CFRelease(keyUp);

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(120 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            // 2. Type "http://127.0.0.1:4545/#settings" into the new tab's omnibox
            NSString *urlStr = @"http://127.0.0.1:4545/#settings";
            for (NSUInteger i = 0; i < [urlStr length]; i++) {
                unichar c = [urlStr characterAtIndex:i];
                CGEventRef charEvent = CGEventCreateKeyboardEvent(NULL, 0, true);
                CGEventKeyboardSetUnicodeString(charEvent, 1, &c);
                CGEventRef charUpEvent = CGEventCreateKeyboardEvent(NULL, 0, false);
                CGEventKeyboardSetUnicodeString(charUpEvent, 1, &c);
                CGEventPost(kCGHIDEventTap, charEvent);
                CGEventPost(kCGHIDEventTap, charUpEvent);
                CFRelease(charEvent);
                CFRelease(charUpEvent);
            }

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                // 3. Press Return (keycode 36)
                CGKeyCode kc_ret = 36;
                CGEventRef kd_ret = CGEventCreateKeyboardEvent(NULL, kc_ret, true);
                CGEventRef ku_ret = CGEventCreateKeyboardEvent(NULL, kc_ret, false);
                CGEventPost(kCGHIDEventTap, kd_ret);
                CGEventPost(kCGHIDEventTap, ku_ret);
                CFRelease(kd_ret);
                CFRelease(ku_ret);

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(200 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                    force_refresh_tabs();
                });
            });
        });
    });
}

@interface AstraMenuHandler : NSObject
+ (instancetype)sharedHandler;
- (void)openSettingsInNewTab:(id)sender;
@end

static void simulate_cmd_number(NSInteger num) {
    CGKeyCode kc = 18; // '1'
    if (num == 2) kc = 19;
    else if (num == 3) kc = 20;
    else if (num == 4) kc = 21;
    else if (num == 5) kc = 23;
    else if (num == 6) kc = 22;
    else if (num == 7) kc = 26;
    else if (num == 8) kc = 28;
    else if (num >= 9) kc = 25; // '9'

    CGEventRef keyDown = CGEventCreateKeyboardEvent(NULL, kc, true);
    CGEventSetFlags(keyDown, kCGEventFlagMaskCommand);
    CGEventRef keyUp = CGEventCreateKeyboardEvent(NULL, kc, false);
    CGEventSetFlags(keyUp, kCGEventFlagMaskCommand);
    CGEventPost(kCGHIDEventTap, keyDown);
    CGEventPost(kCGHIDEventTap, keyUp);
    CFRelease(keyDown);
    CFRelease(keyUp);
}

static void simulate_cmd_w(void) {
    CGKeyCode kc = 13; // 'w'
    CGEventRef keyDown = CGEventCreateKeyboardEvent(NULL, kc, true);
    CGEventSetFlags(keyDown, kCGEventFlagMaskCommand);
    CGEventRef keyUp = CGEventCreateKeyboardEvent(NULL, kc, false);
    CGEventSetFlags(keyUp, kCGEventFlagMaskCommand);
    CGEventPost(kCGHIDEventTap, keyDown);
    CGEventPost(kCGHIDEventTap, keyUp);
    CFRelease(keyDown);
    CFRelease(keyUp);
}

@implementation AstraMenuHandler
+ (instancetype)sharedHandler {
    static AstraMenuHandler *s_h = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_h = [[AstraMenuHandler alloc] init];
    });
    return s_h;
}
- (void)openSettingsInNewTab:(id)sender {
    open_settings_in_new_tab();
}
@end

static void configure_menu_items(void) {
    NSMenu *mainMenu = [NSApp mainMenu];
    if (!mainMenu) return;
    for (NSMenuItem *topItem in [mainMenu itemArray]) {
        if ([topItem hasSubmenu]) {
            for (NSMenuItem *subItem in [[topItem submenu] itemArray]) {
                if ([[subItem keyEquivalent] isEqualToString:@","] ||
                    [[subItem title] containsString:@"Settings"] ||
                    [[subItem title] containsString:@"Preferences"]) {
                    [subItem setTarget:[AstraMenuHandler sharedHandler]];
                    [subItem setAction:@selector(openSettingsInNewTab:)];
                }
            }
        }
    }
}

@implementation AstraVerticalSidebarView
- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setWantsLayer:YES];
        self.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.07 green:0.07 blue:0.08 alpha:1.0].CGColor; // #121214
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.08].CGColor;
        [self setAutoresizingMask:NSViewHeightSizable | NSViewMaxXMargin];

        CGFloat w = frameRect.size.width;
        CGFloat h = frameRect.size.height;

        // Bottom Footer (Settings shortcut)
        _footerView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, w, 44)];
        [_footerView setWantsLayer:YES];
        _footerView.layer.borderWidth = 1.0;
        _footerView.layer.borderColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.06].CGColor;
        [_footerView setAutoresizingMask:NSViewMaxYMargin | NSViewWidthSizable];

        _settingsBtn = [[AstraSettingsButton alloc] initWithFrame:NSMakeRect(12, 6, w - 24, 32)];
        [_settingsBtn setTarget:self];
        [_settingsBtn setAction:@selector(onSettingsClicked:)];
        [_footerView addSubview:_settingsBtn];
        [self addSubview:_footerView];

        // Scrollable Tab Stack (moved up to top spot where branding was)
        CGFloat topInset = 48.0;
        CGFloat bottomInset = 48.0;
        NSRect scrollFrame = NSMakeRect(10, bottomInset, w - 20, h - topInset - bottomInset);
        _scrollView = [[NSScrollView alloc] initWithFrame:scrollFrame];
        [_scrollView setHasVerticalScroller:YES];
        [_scrollView setHasHorizontalScroller:NO];
        [_scrollView setAutohidesScrollers:YES];
        [_scrollView setDrawsBackground:NO];
        [_scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

        _tabContainer = [[AstraFlippedView alloc] initWithFrame:NSMakeRect(0, 0, w - 20, scrollFrame.size.height)];
        [_scrollView setDocumentView:_tabContainer];

        [self addSubview:_scrollView];

        // Collapse Button in top right of sidebar header
        _collapseBtn = [[AstraCollapseButton alloc] initWithFrame:NSMakeRect(w - 38, h - 38, 28, 28)];
        [_collapseBtn setTarget:self];
        [_collapseBtn setAction:@selector(onCollapseClicked:)];
        [_collapseBtn setToolTip:@"Collapse sidebar (⌘B)"];
        [self addSubview:_collapseBtn];

        [self layoutSidebarViews];
    }
    return self;
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    [self layoutSidebarViews];
}

- (void)layoutSidebarViews {
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    if (w <= 0 || h <= 0) return;

    BOOL compact = (w < 100);
    _collapseBtn.isCollapsed = compact;
    [_collapseBtn setToolTip:compact ? @"Expand sidebar (⌘B)" : @"Collapse sidebar (⌘B)"];

    [_footerView setHidden:compact];
    [_scrollView setHidden:compact];

    [_footerView setFrame:NSMakeRect(0, 0, w, 44)];
    [_settingsBtn setFrame:NSMakeRect(12, 6, w - 24, 32)];
    [_settingsBtn setTitle:compact ? @"S" : @"Settings"];
    [_settingsBtn setAlignment:NSTextAlignmentCenter];

    CGFloat btnSize = 28.0;
    [_collapseBtn setFrame:NSMakeRect(w - btnSize - 10.0, h - 38.0, btnSize, btnSize)];

    CGFloat sx = compact ? 6.0 : 10.0;
    CGFloat sw = w - (sx * 2.0);
    CGFloat topInset = 48.0;
    CGFloat bottomInset = 48.0;
    [_scrollView setFrame:NSMakeRect(sx, bottomInset, sw, h - topInset - bottomInset)];
    [_collapseBtn setNeedsDisplay:YES];
}

- (void)onCollapseClicked:(id)sender {
    toggle_sidebar_collapse();
}

- (void)onSettingsClicked:(id)sender {
    open_settings_in_new_tab();
}

- (void)onTabClicked:(AstraTabButton *)sender {
    NSInteger idx = sender.tabIndex;
    [self setActiveTabIndexLocally:idx];

    dispatch_async(dispatch_get_main_queue(), ^{
        simulate_cmd_number(idx);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(40 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            force_refresh_tabs();
        });
    });
}

- (void)onTabCloseClicked:(NSButton *)sender {
    AstraTabButton *parent = (AstraTabButton *)[sender superview];
    if (!parent) return;
    NSInteger idx = parent.tabIndex;
    [self removeTabLocallyAtIndex:idx];

    dispatch_async(dispatch_get_main_queue(), ^{
        simulate_cmd_number(idx);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            simulate_cmd_w();
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(40 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                force_refresh_tabs();
            });
        });
    });
}

- (void)removeActiveTabOptimistically {
    if (_lastActiveIndex > 0 && _lastTitles && _lastActiveIndex <= (NSInteger)[_lastTitles count]) {
        [self removeTabLocallyAtIndex:_lastActiveIndex];
    }
}

- (void)addOptimisticTabWithTitle:(NSString *)title {
    NSMutableArray *newTitles = [_lastTitles mutableCopy];
    if (!newTitles) newTitles = [NSMutableArray array];
    [newTitles addObject:title ? title : @"New Tab"];
    NSInteger newActiveIdx = [newTitles count];
    [self updateTabsWithTitles:newTitles activeIndex:newActiveIdx];
    [self scrollToActiveTab];
}

- (void)setActiveTabIndexLocally:(NSInteger)idx {
    if (_lastTitles) {
        [self updateTabsWithTitles:_lastTitles activeIndex:idx];
        [self scrollToActiveTab];
    }
}

- (void)removeTabLocallyAtIndex:(NSInteger)idx {
    if (_lastTitles && idx > 0 && idx <= (NSInteger)[_lastTitles count]) {
        NSMutableArray *newTitles = [_lastTitles mutableCopy];
        [newTitles removeObjectAtIndex:idx - 1];
        NSInteger newActive = _lastActiveIndex;
        if (newActive > (NSInteger)[newTitles count]) {
            newActive = (NSInteger)[newTitles count];
        }
        [self updateTabsWithTitles:newTitles activeIndex:newActive];
        [self scrollToActiveTab];
    }
}

- (void)scrollToActiveTab {
    if (_lastActiveIndex <= 0) return;
    CGFloat rowH = 36.0;
    CGFloat spacing = 4.0;
    CGFloat y = (_lastActiveIndex - 1) * (rowH + spacing);
    NSRect tabRect = NSMakeRect(0, y, [_scrollView bounds].size.width, rowH);
    NSRect visibleRect = [_scrollView.contentView bounds];

    if (NSContainsRect(visibleRect, tabRect)) {
        return;
    }

    CGFloat targetY = visibleRect.origin.y;
    if (tabRect.origin.y < visibleRect.origin.y) {
        targetY = tabRect.origin.y;
    } else if (NSMaxY(tabRect) > NSMaxY(visibleRect)) {
        targetY = NSMaxY(tabRect) - visibleRect.size.height;
    }
    if (targetY < 0) targetY = 0;
    [_scrollView.contentView scrollToPoint:NSMakePoint(0, targetY)];
    [_scrollView reflectScrolledClipView:_scrollView.contentView];
}

- (void)updateTabsWithTitles:(NSArray *)titles activeIndex:(NSInteger)activeIdx {
    if ([titles isEqualToArray:_lastTitles] && activeIdx == _lastActiveIndex) {
        return; // No change
    }

    NSArray *subviews = [_tabContainer subviews];
    BOOL sameCount = ([subviews count] == [titles count]);

    if (sameCount) {
        _lastTitles = [titles copy];
        _lastActiveIndex = activeIdx;
        for (NSInteger i = 0; i < (NSInteger)[subviews count]; i++) {
            AstraTabButton *btn = (AstraTabButton *)subviews[i];
            btn.tabIndex = i + 1;
            btn.isCurrent = (btn.tabIndex == activeIdx);
            btn.rawTitle = AstraSanitizeTabTitle(titles[i]);
            [btn updateAppearance];
            [btn setToolTip:btn.rawTitle];
            [btn.closeBtn setAlphaValue:btn.isCurrent ? 0.7 : 0.0];
        }
        [self scrollToActiveTab];
        return;
    }

    _lastTitles = [titles copy];
    _lastActiveIndex = activeIdx;

    // Remove old subviews
    NSArray *views = [[_tabContainer subviews] copy];
    for (NSView *v in views) {
        [v removeFromSuperview];
    }

    CGFloat itemWidth = [_scrollView bounds].size.width;
    if (itemWidth < 100) itemWidth = 196.0;

    CGFloat rowH = 36.0;
    CGFloat spacing = 4.0;
    CGFloat totalH = [titles count] * (rowH + spacing);

    NSRect docFrame = [_tabContainer frame];
    docFrame.size.width = itemWidth;
    docFrame.size.height = MAX(totalH, [_scrollView bounds].size.height);
    [_tabContainer setFrame:docFrame];

    if (totalH <= [_scrollView bounds].size.height) {
        [_scrollView.contentView scrollToPoint:NSMakePoint(0, 0)];
        [_scrollView reflectScrolledClipView:_scrollView.contentView];
    }

    for (NSInteger i = 0; i < (NSInteger)[titles count]; i++) {
        NSString *title = titles[i];
        NSInteger tabIdx = i + 1;
        BOOL isCurr = (tabIdx == activeIdx);

        CGFloat y = i * (rowH + spacing);
        AstraTabButton *btn = [[AstraTabButton alloc] initWithFrame:NSMakeRect(0, y, itemWidth, rowH)
                                                              title:title
                                                              index:tabIdx
                                                          isCurrent:isCurr];
        [btn setTarget:self];
        [btn setAction:@selector(onTabClicked:)];

        [btn.closeBtn setTarget:self];
        [btn.closeBtn setAction:@selector(onTabCloseClicked:)];

        [_tabContainer addSubview:btn];
    }
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint loc = [self convertPoint:[event locationInWindow] fromView:nil];
    if (_collapseBtn && NSPointInRect(loc, _collapseBtn.frame)) {
        [_collapseBtn performClick:nil];
        return;
    }
    if (loc.y >= self.bounds.size.height - 48.0) {
        [self.window performWindowDragWithEvent:event];
        return;
    }
    [super mouseDown:event];
}
@end

/* ─── Astra Top Cover Bar (Covers horizontal tabs in vertical mode) ────────── */
@interface AstraTopCoverView : NSView
@property (nonatomic, strong) CALayer *bottomBorder;
@end

@implementation AstraTopCoverView
- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setWantsLayer:YES];
        self.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.071 green:0.071 blue:0.078 alpha:1.0].CGColor; // #121214
        _bottomBorder = [CALayer layer];
        _bottomBorder.backgroundColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.08].CGColor;
        [self.layer addSublayer:_bottomBorder];
        [self setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
    }
    return self;
}

- (void)layout {
    [super layout];
    if (_bottomBorder) {
        _bottomBorder.frame = CGRectMake(0, 0, self.bounds.size.width, 1.0);
    }
}

- (void)mouseDown:(NSEvent *)event {
    if ([event clickCount] == 2) {
        [self.window zoom:nil];
        return;
    }
    [self.window performWindowDragWithEvent:event];
}
@end

/* ─── Setting Reader & Native Command Bridge ─────────────────────────────── */
static void configure_window(NSWindow *win);

static NSDictionary *read_all_astra_settings(void) {
    NSString *home = NSHomeDirectory();
    NSString *jsonPath = [home stringByAppendingPathComponent:@"Library/Application Support/Astra/astra_settings.json"];
    NSData *data = [NSData dataWithContentsOfFile:jsonPath];
    if (data) {
        NSError *err = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        if ([dict isKindOfClass:[NSDictionary class]]) {
            return dict;
        }
    }
    return nil;
}

static NSString *s_cached_tab_orientation = nil;
static NSString *s_cached_vtab_width = nil;
static NSDate *s_last_leveldb_mtime = nil;
static unsigned long long s_last_leveldb_size = 0;

static NSString *read_leveldb_setting(NSString *key) {
    NSString *home = NSHomeDirectory();
    NSString *dbDir = [home stringByAppendingPathComponent:@"Library/Application Support/Astra/Default/Local Storage/leveldb"];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dbDir error:nil];
    if (!files || [files count] == 0) return nil;
    
    NSMutableArray *sortedLogs = [NSMutableArray array];
    for (NSString *fname in files) {
        if ([fname hasSuffix:@".log"] || [fname hasSuffix:@".ldb"]) {
            NSString *fpath = [dbDir stringByAppendingPathComponent:fname];
            [sortedLogs addObject:fpath];
        }
    }
    
    [sortedLogs sortUsingComparator:^NSComparisonResult(NSString *p1, NSString *p2) {
        NSDictionary *a1 = [[NSFileManager defaultManager] attributesOfItemAtPath:p1 error:nil];
        NSDictionary *a2 = [[NSFileManager defaultManager] attributesOfItemAtPath:p2 error:nil];
        NSDate *d1 = a1[NSFileModificationDate];
        NSDate *d2 = a2[NSFileModificationDate];
        return [d2 compare:d1];
    }];

    if ([sortedLogs count] > 0) {
        NSString *newest = sortedLogs[0];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:newest error:nil];
        NSDate *curMtime = attrs[NSFileModificationDate];
        unsigned long long curSize = [attrs[NSFileSize] unsignedLongLongValue];
        if (s_last_leveldb_mtime && [s_last_leveldb_mtime isEqualToDate:curMtime] && s_last_leveldb_size == curSize) {
            if ([key isEqualToString:@"tab_orientation"]) return s_cached_tab_orientation;
            if ([key isEqualToString:@"vtab_width"]) return s_cached_vtab_width;
        }
        s_last_leveldb_mtime = curMtime;
        s_last_leveldb_size = curSize;
    }

    NSString *needle = [NSString stringWithFormat:@"\"%@\":", key];
    const char *target = [needle UTF8String];
    size_t targetLen = strlen(target);

    for (NSString *fpath in sortedLogs) {
        NSData *d = [NSData dataWithContentsOfFile:fpath];
        if (!d) continue;
        const char *bytes = (const char *)[d bytes];
        NSUInteger len = [d length];
        if (len < targetLen + 5) continue;
        for (NSInteger i = (NSInteger)len - (NSInteger)targetLen - 5; i >= 0; i--) {
            if (strncmp(bytes + i, target, targetLen) == 0) {
                const char *p = bytes + i + targetLen;
                while (*p == ' ' || *p == '\t') p++;
                if (*p == '"') {
                    p++;
                    char valBuf[64];
                    int vi = 0;
                    while (*p != '"' && *p != '\n' && *p != '\r' && vi < 63) {
                        valBuf[vi++] = *p++;
                    }
                    valBuf[vi] = '\0';
                    NSString *res = [NSString stringWithUTF8String:valBuf];
                    if ([key isEqualToString:@"tab_orientation"]) s_cached_tab_orientation = res;
                    if ([key isEqualToString:@"vtab_width"]) s_cached_vtab_width = res;
                    return res;
                } else {
                    char valBuf[64];
                    int vi = 0;
                    while (*p != ',' && *p != '}' && *p != ' ' && *p != '\n' && *p != '\r' && vi < 63) {
                        valBuf[vi++] = *p++;
                    }
                    valBuf[vi] = '\0';
                    NSString *res = [NSString stringWithUTF8String:valBuf];
                    if ([key isEqualToString:@"tab_orientation"]) s_cached_tab_orientation = res;
                    if ([key isEqualToString:@"vtab_width"]) s_cached_vtab_width = res;
                    return res;
                }
            }
        }
    }
    if ([key isEqualToString:@"tab_orientation"]) return s_cached_tab_orientation;
    if ([key isEqualToString:@"vtab_width"]) return s_cached_vtab_width;
    return nil;
}

static BOOL read_tab_orientation_setting(void) {
    NSDictionary *dict = read_all_astra_settings();
    if (dict && dict[@"tab_orientation"]) {
        NSString *ori = dict[@"tab_orientation"];
        if ([ori isEqualToString:@"horizontal"]) return NO;
        if ([ori isEqualToString:@"vertical"]) return YES;
    }
    NSString *fromDb = read_leveldb_setting(@"tab_orientation");
    if (fromDb) {
        if ([fromDb isEqualToString:@"horizontal"]) return NO;
        if ([fromDb isEqualToString:@"vertical"]) return YES;
    }
    return YES;
}

static BOOL s_sidebar_collapsed = NO;
static BOOL s_is_animating_sidebar = NO;
static dispatch_source_t s_sidebar_anim_timer = nil;
static NSTimeInterval s_anim_start_time = 0.0;
static CGFloat s_anim_start_progress = 1.0;
static CGFloat s_anim_target_progress = 0.0;
static CGFloat s_sidebar_anim_progress = -1.0;
static const NSTimeInterval kSidebarAnimDuration = 0.22;

static CGFloat ease_out_cubic(CGFloat t) {
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;
    CGFloat inv = 1.0 - t;
    return 1.0 - (inv * inv * inv);
}

static BOOL read_sidebar_collapsed_setting(void) {
    NSDictionary *dict = read_all_astra_settings();
    if (dict && dict[@"sidebar_collapsed"]) {
        return [dict[@"sidebar_collapsed"] boolValue];
    }
    return NO;
}

static void start_sidebar_animation(BOOL expand) {
    if (s_sidebar_anim_timer) {
        dispatch_source_cancel(s_sidebar_anim_timer);
        s_sidebar_anim_timer = nil;
    }

    if (s_sidebar_anim_progress < 0.0) {
        s_sidebar_anim_progress = expand ? 0.0 : 1.0;
    }

    s_anim_start_time = [NSDate timeIntervalSinceReferenceDate];
    s_anim_start_progress = s_sidebar_anim_progress;
    s_anim_target_progress = expand ? 1.0 : 0.0;
    s_is_animating_sidebar = YES;

    s_sidebar_anim_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    if (!s_sidebar_anim_timer) return;

    dispatch_source_set_timer(s_sidebar_anim_timer,
                              dispatch_time(DISPATCH_TIME_NOW, 0),
                              8 * NSEC_PER_MSEC,
                              1 * NSEC_PER_MSEC);

    dispatch_source_set_event_handler(s_sidebar_anim_timer, ^{
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval elapsed = now - s_anim_start_time;
        CGFloat t = (CGFloat)(elapsed / kSidebarAnimDuration);

        if (t >= 1.0) {
            s_sidebar_anim_progress = s_anim_target_progress;
            s_is_animating_sidebar = NO;
            if (s_sidebar_anim_timer) {
                dispatch_source_cancel(s_sidebar_anim_timer);
                s_sidebar_anim_timer = nil;
            }
            for (NSWindow *win in [NSApp windows]) {
                configure_window(win);
            }
            if (s_anim_target_progress > 0.5 && s_currentSidebarView) {
                query_and_update_tabs(s_currentSidebarView);
            }
            return;
        }

        CGFloat eased = ease_out_cubic(t);
        s_sidebar_anim_progress = s_anim_start_progress + (s_anim_target_progress - s_anim_start_progress) * eased;

        for (NSWindow *win in [NSApp windows]) {
            configure_window(win);
        }
    });

    dispatch_resume(s_sidebar_anim_timer);
}

static void toggle_sidebar_collapse(void) {
    BOOL isCurrentlyCollapsed = read_sidebar_collapsed_setting();
    BOOL newCollapsed = !isCurrentlyCollapsed;
    s_sidebar_collapsed = newCollapsed;

    start_sidebar_animation(!newCollapsed);

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        NSString *home = NSHomeDirectory();
        NSString *confDir = [home stringByAppendingPathComponent:@"Library/Application Support/Astra"];
        NSString *confPath = [confDir stringByAppendingPathComponent:@"astra_settings.json"];
        [[NSFileManager defaultManager] createDirectoryAtPath:confDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:read_all_astra_settings()];
        dict[@"sidebar_collapsed"] = @(newCollapsed);
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
        if (data) {
            [data writeToFile:confPath atomically:YES];
        }
    });
}

static dispatch_source_t s_settings_file_source = nil;
static dispatch_source_t s_leveldb_dir_source = nil;
static int s_settings_fd = -1;
static int s_leveldb_fd = -1;

static void start_settings_watcher(void) {
    if (s_settings_file_source) {
        dispatch_source_cancel(s_settings_file_source);
        s_settings_file_source = nil;
    }
    if (s_leveldb_dir_source) {
        dispatch_source_cancel(s_leveldb_dir_source);
        s_leveldb_dir_source = nil;
    }
    if (s_settings_fd >= 0) {
        close(s_settings_fd);
        s_settings_fd = -1;
    }
    if (s_leveldb_fd >= 0) {
        close(s_leveldb_fd);
        s_leveldb_fd = -1;
    }

    NSString *home = NSHomeDirectory();
    NSString *confDir = [home stringByAppendingPathComponent:@"Library/Application Support/Astra"];
    [[NSFileManager defaultManager] createDirectoryAtPath:confDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *confPath = [confDir stringByAppendingPathComponent:@"astra_settings.json"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:confPath]) {
        [@"{\"tab_orientation\":\"vertical\"}\n" writeToFile:confPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }

    // 1. Watch astra_settings.json
    s_settings_fd = open([confPath UTF8String], O_EVTONLY);
    if (s_settings_fd >= 0) {
        s_settings_file_source = dispatch_source_create(
            DISPATCH_SOURCE_TYPE_VNODE,
            s_settings_fd,
            DISPATCH_VNODE_WRITE | DISPATCH_VNODE_DELETE | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_REVOKE,
            dispatch_get_main_queue()
        );
        if (s_settings_file_source) {
            dispatch_source_set_event_handler(s_settings_file_source, ^{
                unsigned long flags = dispatch_source_get_data(s_settings_file_source);
                if (!s_is_animating_sidebar) {
                    read_tab_orientation_setting();
                    s_sidebar_collapsed = read_sidebar_collapsed_setting();
                    for (NSWindow *win in [NSApp windows]) {
                        configure_window(win);
                    }
                }
                if (flags & (DISPATCH_VNODE_DELETE | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_REVOKE)) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                        start_settings_watcher();
                    });
                }
            });
            dispatch_source_set_cancel_handler(s_settings_file_source, ^{
                if (s_settings_fd >= 0) {
                    close(s_settings_fd);
                    s_settings_fd = -1;
                }
            });
            dispatch_resume(s_settings_file_source);
        }
    }

    // 2. Watch LevelDB directory (kernel sends VNODE_WRITE when localStorage log updates)
    NSString *dbDir = [confDir stringByAppendingPathComponent:@"Default/Local Storage/leveldb"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dbDir withIntermediateDirectories:YES attributes:nil error:nil];
    s_leveldb_fd = open([dbDir UTF8String], O_EVTONLY);
    if (s_leveldb_fd >= 0) {
        s_leveldb_dir_source = dispatch_source_create(
            DISPATCH_SOURCE_TYPE_VNODE,
            s_leveldb_fd,
            DISPATCH_VNODE_WRITE | DISPATCH_VNODE_ATTRIB,
            dispatch_get_main_queue()
        );
        if (s_leveldb_dir_source) {
            dispatch_source_set_event_handler(s_leveldb_dir_source, ^{
                if (!s_is_animating_sidebar) {
                    read_tab_orientation_setting();
                    for (NSWindow *win in [NSApp windows]) {
                        configure_window(win);
                    }
                }
            });
            dispatch_source_set_cancel_handler(s_leveldb_dir_source, ^{
                if (s_leveldb_fd >= 0) {
                    close(s_leveldb_fd);
                    s_leveldb_fd = -1;
                }
            });
            dispatch_resume(s_leveldb_dir_source);
        }
    }
}

static CGFloat read_sidebar_width_setting(void) {
    NSString *w = read_leveldb_setting(@"vtab_width");
    if (!w) {
        NSDictionary *dict = read_all_astra_settings();
        if (dict) w = dict[@"vtab_width"];
    }
    if ([w isEqualToString:@"compact"]) return 56.0;
    return 220.0;
}

static void (*orig_setTitle)(id, SEL, NSString *) = NULL;

static void handle_astra_command(NSString *cmdString) {
    if (!cmdString || ![cmdString hasPrefix:@"__astra_cmd__:"]) return;
    NSString *query = [cmdString substringFromIndex:[@"__astra_cmd__:" length]];
    NSArray *parts = [query componentsSeparatedByString:@"&"];
    NSString *jsonStr = nil;
    NSString *key = nil;
    NSString *val = nil;
    for (NSString *part in parts) {
        if ([part hasPrefix:@"json="]) {
            jsonStr = [[part substringFromIndex:5] stringByRemovingPercentEncoding];
        } else if ([part hasPrefix:@"key="]) {
            key = [[part substringFromIndex:4] stringByRemovingPercentEncoding];
        } else if ([part hasPrefix:@"val="]) {
            val = [[part substringFromIndex:4] stringByRemovingPercentEncoding];
        }
    }

    if (key && [key isEqualToString:@"sidebar_collapsed"] && val) {
        s_sidebar_collapsed = [val boolValue];
    } else if (jsonStr) {
        NSData *d = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        if (d) {
            NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
            if ([parsed isKindOfClass:[NSDictionary class]]) {
                if (parsed[@"sidebar_collapsed"]) {
                    s_sidebar_collapsed = [parsed[@"sidebar_collapsed"] boolValue];
                }
            }
        }
    }

    NSString *home = NSHomeDirectory();
    NSString *confDir = [home stringByAppendingPathComponent:@"Library/Application Support/Astra"];
    NSString *confPath = [confDir stringByAppendingPathComponent:@"astra_settings.json"];
    [[NSFileManager defaultManager] createDirectoryAtPath:confDir withIntermediateDirectories:YES attributes:nil error:nil];

    if (jsonStr && [jsonStr length] > 0) {
        [jsonStr writeToFile:confPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    } else if (key && val) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:read_all_astra_settings()];
        dict[key] = val;
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
        if (data) {
            [data writeToFile:confPath atomically:YES];
        }
    }

    // Immediately update layout across all windows synchronously on the main thread!
    for (NSWindow *win in [NSApp windows]) {
        configure_window(win);
    }
}

static void astra_swizzled_setTitle(NSWindow *self, SEL _cmd, NSString *title) {
    if (title && [title hasPrefix:@"__astra_cmd__:"]) {
        handle_astra_command(title);
        if (orig_setTitle) {
            orig_setTitle(self, _cmd, @"");
        }
        return;
    }
    if (orig_setTitle) {
        orig_setTitle(self, _cmd, title);
    }
}

/* ─── Window Layout Manager ───────────────────────────────────────────────── */
#import <objc/runtime.h>

static BOOL s_is_fullscreen_transitioning = NO;

static BOOL is_exclusive_access_bubble(NSWindow *w) {
    if (!w) return NO;
    if (![[w className] isEqualToString:@"NativeWidgetMacNSWindow"]) return NO;
    NSRect f = [w frame];
    if (f.size.width >= 250 && f.size.width <= 500 && f.size.height >= 35 && f.size.height <= 70) {
        if (f.origin.y > 600) {
            return YES;
        }
    }
    return NO;
}

static void (*orig_orderWindow)(id, SEL, NSWindowOrderingMode, NSInteger) = NULL;
static void (*orig_setAlphaValue)(id, SEL, CGFloat) = NULL;

static void astra_swizzled_orderWindow(NSWindow *self, SEL _cmd, NSWindowOrderingMode mode, NSInteger otherWindowNumber) {
    if (is_exclusive_access_bubble(self)) {
        if (orig_setAlphaValue) orig_setAlphaValue(self, @selector(setAlphaValue:), 0.0);
        [self setIgnoresMouseEvents:YES];
        if (orig_orderWindow) {
            orig_orderWindow(self, _cmd, NSWindowOut, 0);
        }
        return;
    }
    if (orig_orderWindow) {
        orig_orderWindow(self, _cmd, mode, otherWindowNumber);
    }
}

static void astra_swizzled_setAlphaValue(NSWindow *self, SEL _cmd, CGFloat alpha) {
    if (is_exclusive_access_bubble(self)) {
        if (orig_setAlphaValue) {
            orig_setAlphaValue(self, _cmd, 0.0);
        }
        return;
    }
    if (orig_setAlphaValue) {
        orig_setAlphaValue(self, _cmd, alpha);
    }
}

static void suppress_exclusive_access_bubble(void) {
    for (NSWindow *w in [NSApp windows]) {
        if (is_exclusive_access_bubble(w)) {
            if (orig_setAlphaValue) {
                orig_setAlphaValue(w, @selector(setAlphaValue:), 0.0);
            } else {
                [w setAlphaValue:0.0];
            }
            [w setIgnoresMouseEvents:YES];
            if (orig_orderWindow) {
                orig_orderWindow(w, @selector(orderWindow:relativeTo:), NSWindowOut, 0);
            }
        }
    }
}

static void configure_fullscreen_toolbar(void) {
    suppress_exclusive_access_bubble();
    for (NSWindow *w in [NSApp windows]) {
        if ([[w className] isEqualToString:@"NSToolbarFullScreenWindow"]) {
            NSView *cv = [w contentView];
            if (!cv) continue;
            NSMutableArray *queue = [NSMutableArray arrayWithObject:cv];
            while ([queue count] > 0) {
                NSView *v = [queue firstObject];
                [queue removeObjectAtIndex:0];
                if (![v isKindOfClass:[NSView class]]) continue;
                
                NSString *cls = [v className];
                if ([cls isEqualToString:@"ViewsCompositorSuperview"] || [cls isEqualToString:@"BridgedContentView"]) {
                    if (v.frame.size.height >= 35.0 && v.frame.size.height <= 50.0) {
                        if (![v isHidden]) {
                            [v setHidden:YES];
                        }
                    }
                }
                
                for (NSView *c in [v subviews]) {
                    if ([c isKindOfClass:[NSView class]]) {
                        [queue addObject:c];
                    }
                }
            }
        }
    }
}

static void update_window_layout(NSWindow *win) {
    if (!win) return;
    if (s_is_fullscreen_transitioning) return;
    if ([win inLiveResize]) return;
    if (![[win className] isEqualToString:@"BrowserNativeWidgetWindow"]) return;

    NSView *cv = [win contentView];
    if (!cv) return;

    NSRect winRect = [win contentLayoutRect];
    if (winRect.size.width < 300 || winRect.size.height < 300) {
        winRect = [win frame];
    }
    CGFloat winWidth = winRect.size.width;
    CGFloat winHeight = winRect.size.height;
    if (winWidth < 300 || winHeight < 300) return;

    BOOL isFullscreen = (win.styleMask & NSWindowStyleMaskFullScreen) != 0;
    if (isFullscreen) {
        configure_fullscreen_toolbar();
    }
    BOOL isVertical = read_tab_orientation_setting();
    BOOL isCollapsedSetting = read_sidebar_collapsed_setting();

    if (!s_is_animating_sidebar) {
        s_sidebar_anim_progress = isCollapsedSetting ? 0.0 : 1.0;
    }
    CGFloat p = s_sidebar_anim_progress;
    if (p < 0.0) p = 0.0;
    if (p > 1.0) p = 1.0;

    CGFloat baseSidebarWidth = read_sidebar_width_setting();
    CGFloat minSidebarWidth = 48.0;
    CGFloat currentSidebarWidth = minSidebarWidth + (baseSidebarWidth - minSidebarWidth) * p;
    CGFloat animatedSidebarWidth = isVertical ? currentSidebarWidth : 0.0;
    CGFloat vTopBarHeight = isFullscreen ? 0.0 : 41.0;

    NSView *viewsCompositor = nil;
    NSMutableArray *allWebContentsViews = [NSMutableArray array];
    AstraVerticalSidebarView *sidebarView = nil;
    AstraTopCoverView *topCoverView = nil;

    for (NSView *sub in [cv subviews]) {
        NSString *cls = [sub className];
        if ([cls isEqualToString:@"ViewsCompositorSuperview"]) {
            viewsCompositor = sub;
        } else if ([cls isEqualToString:@"WebContentsViewCocoa"]) {
            [allWebContentsViews addObject:sub];
        } else if ([sub isKindOfClass:[AstraVerticalSidebarView class]]) {
            sidebarView = (AstraVerticalSidebarView *)sub;
        } else if ([sub isKindOfClass:[AstraTopCoverView class]]) {
            topCoverView = (AstraTopCoverView *)sub;
        }
    }

    if (isVertical) {
        // Position ViewsCompositorSuperview so it extends 41pt above window to push tab strip off-screen,
        // while starting at y = 0.0 to fill all the way to the bottom with 0px gap!
        if (viewsCompositor) {
            if ([viewsCompositor isHidden]) [viewsCompositor setHidden:NO];
            NSRect compFrame = NSMakeRect(animatedSidebarWidth, 0.0, winWidth - animatedSidebarWidth, winHeight + 41.0);
            if (!NSEqualRects([viewsCompositor frame], compFrame)) {
                [viewsCompositor setFrame:compFrame];
            }
        }

        // Adjust WebContentsViewCocoa to start at animatedSidebarWidth and fill 100% height from bottom to top
        NSRect contentFrame = NSMakeRect(animatedSidebarWidth, 0.0, winWidth - animatedSidebarWidth, winHeight);
        for (NSView *wc in allWebContentsViews) {
            if (!NSEqualRects([wc frame], contentFrame)) {
                [wc setFrame:contentFrame];
            }
            for (NSView *sub in [wc subviews]) {
                if (!NSEqualRects([sub frame], NSMakeRect(0, 0, contentFrame.size.width, contentFrame.size.height))) {
                    [sub setFrame:NSMakeRect(0, 0, contentFrame.size.width, contentFrame.size.height)];
                }
            }
        }

        // Astra Top Cover Bar to cover horizontal tabs in vertical mode
        NSRect topCoverFrame = NSMakeRect(0.0, winHeight - 41.0, winWidth, 41.0);
        if (!topCoverView) {
            topCoverView = [[AstraTopCoverView alloc] initWithFrame:topCoverFrame];
            [cv addSubview:topCoverView positioned:NSWindowAbove relativeTo:nil];
        } else {
            if ([topCoverView isHidden]) [topCoverView setHidden:NO];
            if (!NSEqualRects([topCoverView frame], topCoverFrame)) {
                [topCoverView setFrame:topCoverFrame];
            }
            [cv addSubview:topCoverView positioned:NSWindowAbove relativeTo:nil];
        }

        // Vertical sidebar view positioning & width animation
        NSRect targetSidebarFrame = NSMakeRect(0.0, 0.0, currentSidebarWidth, winHeight);
        if (!sidebarView) {
            sidebarView = [[AstraVerticalSidebarView alloc] initWithFrame:targetSidebarFrame];
            [cv addSubview:sidebarView positioned:NSWindowAbove relativeTo:topCoverView];
        } else {
            if ([sidebarView isHidden]) [sidebarView setHidden:NO];
            if (!NSEqualRects([sidebarView frame], targetSidebarFrame)) {
                [sidebarView setFrame:targetSidebarFrame];
            }
            [cv addSubview:sidebarView positioned:NSWindowAbove relativeTo:topCoverView];
        }
        [sidebarView setAlphaValue:MAX(0.0, MIN(1.0, 0.3 + 0.7 * p))];
        if (sidebarView.collapseBtn) {
            sidebarView.collapseBtn.isCollapsed = (p < 0.5);
            [sidebarView.collapseBtn setNeedsDisplay:YES];
        }
        s_currentSidebarView = sidebarView;

        // Query open tabs when expanded and not animating
        if (p >= 0.9 && !s_is_animating_sidebar && sidebarView) {
            static NSTimeInterval s_last_query = 0;
            NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
            if (now - s_last_query > 0.08) {
                s_last_query = now;
                query_and_update_tabs(sidebarView);
            }
        }
    } else {
        // Horizontal Tabs mode: restore native top tab strip
        s_sidebar_anim_progress = 1.0;
        if (sidebarView && ![sidebarView isHidden]) {
            [sidebarView setHidden:YES];
        }
        if (s_currentSidebarView == sidebarView) {
            s_currentSidebarView = nil;
        }
        if (topCoverView && ![topCoverView isHidden]) {
            [topCoverView setHidden:YES];
        }
        if (viewsCompositor) {
            if ([viewsCompositor isHidden]) [viewsCompositor setHidden:NO];
            NSRect fullCompFrame = NSMakeRect(0.0, 32.0, winWidth, winHeight - 32.0);
            if (!NSEqualRects([viewsCompositor frame], fullCompFrame)) {
                [viewsCompositor setFrame:fullCompFrame];
            }
        }
        CGFloat hTopTabHeight = isFullscreen ? 0.0 : 41.0;
        for (NSView *wc in allWebContentsViews) {
            NSRect targetFrame = NSMakeRect(0.0, 0.0, winWidth, winHeight - hTopTabHeight);
            if (!NSEqualRects([wc frame], targetFrame)) {
                [wc setFrame:targetFrame];
                for (NSView *sub in [wc subviews]) {
                    [sub setFrame:NSMakeRect(0.0, 0.0, targetFrame.size.width, targetFrame.size.height)];
                }
            }
        }
    }
}

static void configure_window(NSWindow *win) {
    if (!win) return;
    if (s_is_fullscreen_transitioning) return;
    if ([win inLiveResize]) return;
    if (![[win className] isEqualToString:@"BrowserNativeWidgetWindow"]) return;

    [win setTitleVisibility:NSWindowTitleHidden];
    [win setTitle:@""];
    [win setStyleMask:[win styleMask] | NSWindowStyleMaskFullSizeContentView];
    [win setTitlebarAppearsTransparent:YES];

    BOOL isFullscreen = (win.styleMask & NSWindowStyleMaskFullScreen) != 0;
    if (!isFullscreen) {
        static BOOL s_checked_initial_center = NO;
        if (!s_checked_initial_center) {
            s_checked_initial_center = YES;
            NSRect frame = [win frame];
            if (frame.size.width > 200 && frame.size.height > 200) {
                BOOL onScreen = NO;
                for (NSScreen *s in [NSScreen screens]) {
                    if (NSIntersectsRect(frame, [s frame])) {
                        onScreen = YES;
                        break;
                    }
                }
                if (!onScreen && [NSScreen mainScreen]) {
                    [win center];
                }
            }
        }
    }

    update_window_layout(win);
}

__attribute__((constructor))
static void install_astra_hook(void) {
    if (strcmp(getprogname(), "Astra_bin") != 0) return;

    Method m_order = class_getInstanceMethod([NSWindow class], @selector(orderWindow:relativeTo:));
    if (m_order) {
        orig_orderWindow = (void (*)(id, SEL, NSWindowOrderingMode, NSInteger))method_getImplementation(m_order);
        method_setImplementation(m_order, (IMP)astra_swizzled_orderWindow);
    }

    Method m_alpha = class_getInstanceMethod([NSWindow class], @selector(setAlphaValue:));
    if (m_alpha) {
        orig_setAlphaValue = (void (*)(id, SEL, CGFloat))method_getImplementation(m_alpha);
        method_setImplementation(m_alpha, (IMP)astra_swizzled_setAlphaValue);
    }

    Method m_title = class_getInstanceMethod([NSWindow class], @selector(setTitle:));
    if (m_title) {
        orig_setTitle = (void (*)(id, SEL, NSString *))method_getImplementation(m_title);
        method_setImplementation(m_title, (IMP)astra_swizzled_setTitle);
    }

    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
        NSEventModifierFlags flags = [event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
        if (flags & NSEventModifierFlagCommand) {
            NSString *chars = [event charactersIgnoringModifiers];
            if ([chars isEqualToString:@","]) {
                open_settings_in_new_tab();
                return nil;
            } else if ([chars isEqualToString:@"t"]) {
                if (s_currentSidebarView) {
                    [s_currentSidebarView addOptimisticTabWithTitle:@"New Tab"];
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(35 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                    force_refresh_tabs();
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                    force_refresh_tabs();
                });
                return event;
            } else if ([chars isEqualToString:@"w"]) {
                if (s_currentSidebarView) {
                    [s_currentSidebarView removeActiveTabOptimistically];
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(40 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                    force_refresh_tabs();
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(140 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                    force_refresh_tabs();
                });
                return event;
            } else if ([chars isEqualToString:@"b"]) {
                toggle_sidebar_collapse();
                return nil;
            } else if ([chars isEqualToString:@"s"] && (flags & NSEventModifierFlagShift)) {
                toggle_sidebar_collapse();
                return nil;
            }
        }
        return event;
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        NSWindow *win = note.object;
        configure_window(win);
        configure_menu_items();
    }];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserverForName:NSWindowWillEnterFullScreenNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        s_is_fullscreen_transitioning = YES;
    }];
    [nc addObserverForName:NSWindowDidEnterFullScreenNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        s_is_fullscreen_transitioning = NO;
        NSWindow *win = note.object;
        if ([win isKindOfClass:[NSWindow class]]) {
            configure_window(win);
        }
    }];
    [nc addObserverForName:NSWindowWillExitFullScreenNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        s_is_fullscreen_transitioning = YES;
    }];
    [nc addObserverForName:NSWindowDidExitFullScreenNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        s_is_fullscreen_transitioning = NO;
        NSWindow *win = note.object;
        if ([win isKindOfClass:[NSWindow class]]) {
            configure_window(win);
        }
    }];

    s_sidebar_collapsed = read_sidebar_collapsed_setting();
    start_settings_watcher();

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(200 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.08 repeats:YES block:^(NSTimer * _Nonnull timer) {
            configure_menu_items();
            suppress_exclusive_access_bubble();
            for (NSWindow *win in [NSApp windows]) {
                configure_window(win);
            }
        }];
    });
}
