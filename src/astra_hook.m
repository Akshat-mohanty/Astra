#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

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

/* ─── Astra Vertical Sidebar View ─────────────────────────────────────────── */
@interface AstraVerticalSidebarView : NSView
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) AstraFlippedView *tabContainer;
@property (nonatomic, strong) NSView *footerView;
@property (nonatomic, strong) AstraSettingsButton *settingsBtn;
@property (nonatomic, strong) NSArray *lastTitles;
@property (nonatomic, assign) NSInteger lastActiveIndex;
- (void)layoutSidebarViews;
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
    if (now - s_last_open_settings < 0.4) {
        return; // Prevent duplicate rapid invocation
    }
    s_last_open_settings = now;

    if (s_currentSidebarView) {
        [s_currentSidebarView addOptimisticTabWithTitle:@"Settings"];
    }

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *src = @"tell application \"Astra\" to tell window 1\n"
                         "set newTab to make new tab with properties {URL:\"chrome://settings\"}\n"
                         "set active tab index to (count of tabs)\n"
                         "end tell";
        NSAppleScript *as = [[NSAppleScript alloc] initWithSource:src];
        [as executeAndReturnError:nil];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(35 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            force_refresh_tabs();
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            force_refresh_tabs();
        });
    });
}

@interface AstraMenuHandler : NSObject
+ (instancetype)sharedHandler;
- (void)openSettingsInNewTab:(id)sender;
@end

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

    [_footerView setFrame:NSMakeRect(0, 0, w, 44)];
    if (compact) {
        [_settingsBtn setFrame:NSMakeRect(8, 6, w - 16, 32)];
        [_settingsBtn setTitle:@"Settings"];
        [_settingsBtn setAlignment:NSTextAlignmentCenter];
    } else {
        [_settingsBtn setFrame:NSMakeRect(12, 6, w - 24, 32)];
        [_settingsBtn setTitle:@"Settings"];
        [_settingsBtn setAlignment:NSTextAlignmentCenter];
    }

    CGFloat sx = compact ? 6.0 : 10.0;
    CGFloat sw = w - (sx * 2.0);
    CGFloat topInset = 48.0;
    CGFloat bottomInset = 48.0;
    [_scrollView setFrame:NSMakeRect(sx, bottomInset, sw, h - topInset - bottomInset)];
}

- (void)onSettingsClicked:(id)sender {
    open_settings_in_new_tab();
}

- (void)onTabClicked:(AstraTabButton *)sender {
    NSInteger idx = sender.tabIndex;
    [self setActiveTabIndexLocally:idx];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *src = [NSString stringWithFormat:
            @"tell application \"Astra\" to tell window 1 to set active tab index to %ld", (long)idx];
        NSAppleScript *as = [[NSAppleScript alloc] initWithSource:src];
        [as executeAndReturnError:nil];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            force_refresh_tabs();
        });
    });
}

- (void)onTabCloseClicked:(NSButton *)sender {
    AstraTabButton *parent = (AstraTabButton *)[sender superview];
    if (!parent) return;
    NSInteger idx = parent.tabIndex;
    [self removeTabLocallyAtIndex:idx];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *src = [NSString stringWithFormat:
            @"tell application \"Astra\" to close tab %ld of window 1", (long)idx];
        NSAppleScript *as = [[NSAppleScript alloc] initWithSource:src];
        [as executeAndReturnError:nil];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            force_refresh_tabs();
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
@end

/* ─── Astra Top Cover Bar (Covers horizontal tabs in vertical mode) ────────── */
@interface AstraTopCoverView : NSView
@end

@implementation AstraTopCoverView
- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setWantsLayer:YES];
        self.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.07 green:0.07 blue:0.08 alpha:1.0].CGColor; // #121214
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.08].CGColor;
        [self setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
    }
    return self;
}

- (void)mouseDown:(NSEvent *)event {
    [self.window performWindowDragWithEvent:event];
}
@end

/* ─── Setting Reader ──────────────────────────────────────────────────────── */
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

static BOOL read_tab_orientation_setting(void) {
    NSDictionary *dict = read_all_astra_settings();
    if (dict) {
        NSString *ori = dict[@"tab_orientation"];
        if ([ori isEqualToString:@"vertical"]) return YES;
        if ([ori isEqualToString:@"horizontal"]) return NO;
    }

    // Fallback to Local Storage LevelDB log
    NSString *home = NSHomeDirectory();
    NSString *dbDir = [home stringByAppendingPathComponent:@"Library/Application Support/Astra/Default/Local Storage/leveldb"];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dbDir error:nil];
    for (NSString *fname in files) {
        if ([fname hasSuffix:@".log"] || [fname hasSuffix:@".ldb"]) {
            NSString *fpath = [dbDir stringByAppendingPathComponent:fname];
            NSData *d = [NSData dataWithContentsOfFile:fpath];
            if (d) {
                const char *bytes = (const char *)[d bytes];
                NSUInteger len = [d length];
                for (NSInteger i = (NSInteger)len - 40; i >= 0; i--) {
                    if (strncmp(bytes + i, "tab_orientation", 15) == 0) {
                        char chunk[40];
                        strncpy(chunk, bytes + i, 39);
                        chunk[39] = '\0';
                        if (strstr(chunk, "vertical")) return YES;
                        if (strstr(chunk, "horizontal")) return NO;
                    }
                }
            }
        }
    }
    return NO;
}

static CGFloat read_sidebar_width_setting(void) {
    NSDictionary *dict = read_all_astra_settings();
    if (dict) {
        NSString *w = dict[@"vtab_width"];
        if ([w isEqualToString:@"compact"]) return 56.0;
    }
    return 220.0;
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

    NSRect winBounds = [cv bounds];
    if (winBounds.size.width < 300 || winBounds.size.height < 300) return;

    BOOL isFullscreen = (win.styleMask & NSWindowStyleMaskFullScreen) != 0;
    if (isFullscreen) {
        configure_fullscreen_toolbar();
    }
    BOOL isVertical = read_tab_orientation_setting();
    CGFloat sidebarWidth = isVertical ? read_sidebar_width_setting() : 220.0;
    CGFloat topTabHeight = isFullscreen ? 0.0 : 41.0;

    NSView *viewsCompositor = nil;
    NSView *webContentsView = nil;
    AstraVerticalSidebarView *sidebarView = nil;
    AstraTopCoverView *topCoverView = nil;

    for (NSView *sub in [cv subviews]) {
        NSString *cls = [sub className];
        if ([cls isEqualToString:@"ViewsCompositorSuperview"]) {
            viewsCompositor = sub;
        } else if ([cls isEqualToString:@"WebContentsViewCocoa"]) {
            webContentsView = sub;
        } else if ([sub isKindOfClass:[AstraVerticalSidebarView class]]) {
            sidebarView = (AstraVerticalSidebarView *)sub;
        } else if ([sub isKindOfClass:[AstraTopCoverView class]]) {
            topCoverView = (AstraTopCoverView *)sub;
        }
    }

    if (isVertical) {
        NSRect contentFrame = NSMakeRect(sidebarWidth, 0, winBounds.size.width - sidebarWidth, winBounds.size.height - topTabHeight);

        // Position ViewsCompositorSuperview so GPU compositor renders from sidebarWidth to right edge
        if (viewsCompositor) {
            if ([viewsCompositor isHidden]) [viewsCompositor setHidden:NO];
            NSRect compFrame = NSMakeRect(sidebarWidth, 0, winBounds.size.width - sidebarWidth, winBounds.size.height);
            if (!NSEqualRects([viewsCompositor frame], compFrame)) {
                [viewsCompositor setFrame:compFrame];
            }
        }

        // Adjust WebContentsViewCocoa to start at sidebarWidth and fill to the right edge
        if (webContentsView) {
            if (!NSEqualRects([webContentsView frame], contentFrame)) {
                [webContentsView setFrame:contentFrame];
                for (NSView *sub in [webContentsView subviews]) {
                    [sub setFrame:NSMakeRect(0, 0, contentFrame.size.width, contentFrame.size.height)];
                }
            }
        }

        // Cover the top horizontal tabs above webContentsView only in windowed mode
        if (!isFullscreen) {
            NSRect topCoverFrame = NSMakeRect(sidebarWidth, winBounds.size.height - topTabHeight, winBounds.size.width - sidebarWidth, topTabHeight);
            if (!topCoverView) {
                topCoverView = [[AstraTopCoverView alloc] initWithFrame:topCoverFrame];
                [cv addSubview:topCoverView positioned:NSWindowAbove relativeTo:nil];
            } else {
                if ([topCoverView isHidden]) [topCoverView setHidden:NO];
                if (!NSEqualRects([topCoverView frame], topCoverFrame)) {
                    [topCoverView setFrame:topCoverFrame];
                }
            }
        } else {
            if (topCoverView && ![topCoverView isHidden]) {
                [topCoverView setHidden:YES];
            }
        }

        // Create or update vertical sidebar on the left
        NSRect targetSidebarFrame = NSMakeRect(0, 0, sidebarWidth, winBounds.size.height);
        if (!sidebarView) {
            sidebarView = [[AstraVerticalSidebarView alloc] initWithFrame:targetSidebarFrame];
            [cv addSubview:sidebarView positioned:NSWindowAbove relativeTo:nil];
        } else {
            if ([sidebarView isHidden]) [sidebarView setHidden:NO];
            if (!NSEqualRects([sidebarView frame], targetSidebarFrame)) {
                [sidebarView setFrame:targetSidebarFrame];
                sidebarView.lastTitles = nil;
            }
        }
        s_currentSidebarView = sidebarView;

        // Query open tabs and update sidebar with fast, responsive interval
        static NSTimeInterval s_last_query = 0;
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        if (now - s_last_query > 0.08) {
            s_last_query = now;
            query_and_update_tabs(sidebarView);
        }
    } else {
        // Horizontal Tabs mode: restore native top tab strip
        if (viewsCompositor) {
            if ([viewsCompositor isHidden]) [viewsCompositor setHidden:NO];
            NSRect fullCompFrame = NSMakeRect(0, 0, winBounds.size.width, winBounds.size.height);
            if (!NSEqualRects([viewsCompositor frame], fullCompFrame)) {
                [viewsCompositor setFrame:fullCompFrame];
            }
        }
        if (sidebarView && ![sidebarView isHidden]) {
            [sidebarView setHidden:YES];
        }
        if (topCoverView && ![topCoverView isHidden]) {
            [topCoverView setHidden:YES];
        }
        if (webContentsView) {
            NSRect targetFrame = NSMakeRect(0, 0, winBounds.size.width, winBounds.size.height - topTabHeight);
            if (!NSEqualRects([webContentsView frame], targetFrame)) {
                [webContentsView setFrame:targetFrame];
                for (NSView *sub in [webContentsView subviews]) {
                    [sub setFrame:NSMakeRect(0, 0, targetFrame.size.width, targetFrame.size.height)];
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

    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
        if (([event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask) == NSEventModifierFlagCommand) {
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
