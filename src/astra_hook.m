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

    [[NSColor colorWithCalibratedRed:0.49 green:0.36 blue:0.99 alpha:0.35] setFill];
    [chevron fill];
    [[NSColor colorWithCalibratedRed:0.49 green:0.36 blue:0.99 alpha:0.9] setStroke];
    [chevron setLineWidth:1.5];
    [chevron stroke];

    CGContextRestoreGState(ctx);
    #undef SX
    #undef SY
}
@end

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
        _rawTitle = [title copy];

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
        [self setToolTip:title ? title : @"New Tab"];
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
        self.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.49 green:0.36 blue:0.99 alpha:0.25].CGColor;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [NSColor colorWithCalibratedRed:0.49 green:0.36 blue:0.99 alpha:0.45].CGColor;
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

    if (compact) {
        [_closeBtn setHidden:YES];
        NSRect dotRect = NSMakeRect((b.size.width - 8) / 2.0, (b.size.height - 8) / 2.0, 8, 8);
        NSBezierPath *dot = [NSBezierPath bezierPathWithOvalInRect:dotRect];
        if (_isCurrent) {
            [[NSColor colorWithCalibratedRed:0.49 green:0.36 blue:0.99 alpha:1.0] setFill];
        } else {
            [[NSColor colorWithCalibratedWhite:0.6 alpha:0.5] setFill];
        }
        [dot fill];
        return;
    }

    [_closeBtn setHidden:NO];
    // Dot indicator
    NSRect dotRect = NSMakeRect(12, (b.size.height - 7) / 2.0, 7, 7);
    NSBezierPath *dot = [NSBezierPath bezierPathWithOvalInRect:dotRect];
    if (_isCurrent) {
        [[NSColor colorWithCalibratedRed:0.49 green:0.36 blue:0.99 alpha:1.0] setFill];
    } else {
        [[NSColor colorWithCalibratedWhite:0.6 alpha:0.5] setFill];
    }
    [dot fill];

    // Title label
    NSString *t = _rawTitle;
    if (!t || [t length] == 0) t = @"New Tab";

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineBreakMode:NSLineBreakByTruncatingTail];

    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:12.5 weight:_isCurrent ? NSFontWeightSemibold : NSFontWeightRegular],
        NSForegroundColorAttributeName: _isCurrent ? [NSColor whiteColor] : [NSColor colorWithCalibratedWhite:0.7 alpha:1.0],
        NSParagraphStyleAttributeName: style
    };

    NSRect textRect = NSMakeRect(27, (b.size.height - 16) / 2.0, b.size.width - 58, 16);
    [t drawInRect:textRect withAttributes:attrs];
}
@end

/* ─── Astra Vertical Sidebar View ─────────────────────────────────────────── */
@interface AstraVerticalSidebarView : NSView
@property (nonatomic, strong) NSView *headerView;
@property (nonatomic, strong) AstraEmblemView *emblem;
@property (nonatomic, strong) NSTextField *brandLabel;
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) AstraFlippedView *tabContainer;
@property (nonatomic, strong) NSView *footerView;
@property (nonatomic, strong) NSButton *settingsBtn;
@property (nonatomic, strong) NSArray *lastTitles;
@property (nonatomic, assign) NSInteger lastActiveIndex;
- (void)layoutSidebarViews;
@end

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

        // Top Header (Leaves 42px for macOS window traffic lights)
        _headerView = [[NSView alloc] initWithFrame:NSMakeRect(0, h - 84, w, 38)];
        [_headerView setAutoresizingMask:NSViewMinYMargin | NSViewWidthSizable];

        _emblem = [[AstraEmblemView alloc] initWithFrame:NSMakeRect(14, 8, 22, 22)];
        [_headerView addSubview:_emblem];

        _brandLabel = [NSTextField labelWithString:@"Astra"];
        [_brandLabel setFrame:NSMakeRect(42, 9, 80, 20)];
        [_brandLabel setFont:[NSFont systemFontOfSize:14 weight:NSFontWeightBold]];
        [_brandLabel setTextColor:[NSColor colorWithCalibratedWhite:0.96 alpha:1.0]];
        [_headerView addSubview:_brandLabel];

        [self addSubview:_headerView];

        // Bottom Footer (Settings shortcut)
        _footerView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, w, 44)];
        [_footerView setWantsLayer:YES];
        _footerView.layer.borderWidth = 1.0;
        _footerView.layer.borderColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.06].CGColor;
        [_footerView setAutoresizingMask:NSViewMaxYMargin | NSViewWidthSizable];

        _settingsBtn = [[NSButton alloc] initWithFrame:NSMakeRect(12, 6, w - 24, 32)];
        [_settingsBtn setButtonType:NSButtonTypeMomentaryChange];
        [_settingsBtn setBordered:NO];
        [_settingsBtn setTitle:@"⚙  Settings"];
        [_settingsBtn setFont:[NSFont systemFontOfSize:12 weight:NSFontWeightMedium]];
        [_settingsBtn setContentTintColor:[NSColor colorWithCalibratedWhite:0.7 alpha:1.0]];
        [_settingsBtn setTarget:self];
        [_settingsBtn setAction:@selector(onSettingsClicked:)];
        [_footerView addSubview:_settingsBtn];
        [self addSubview:_footerView];

        // Scrollable Tab Stack
        NSRect scrollFrame = NSMakeRect(10, 48, w - 20, h - 92 - 48);
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

    [_headerView setFrame:NSMakeRect(0, h - 84, w, 38)];
    if (compact) {
        [_emblem setFrame:NSMakeRect((w - 22) / 2.0, 8, 22, 22)];
        [_brandLabel setHidden:YES];
    } else {
        [_emblem setFrame:NSMakeRect(14, 8, 22, 22)];
        [_brandLabel setHidden:NO];
        [_brandLabel setFrame:NSMakeRect(42, 9, 80, 20)];
    }

    [_footerView setFrame:NSMakeRect(0, 0, w, 44)];
    if (compact) {
        [_settingsBtn setFrame:NSMakeRect(8, 6, w - 16, 32)];
        [_settingsBtn setTitle:@"⚙"];
    } else {
        [_settingsBtn setFrame:NSMakeRect(12, 6, w - 24, 32)];
        [_settingsBtn setTitle:@"⚙  Settings"];
    }

    CGFloat sx = compact ? 6.0 : 10.0;
    CGFloat sw = w - (sx * 2.0);
    [_scrollView setFrame:NSMakeRect(sx, 48, sw, h - 92 - 48)];
}

- (void)onSettingsClicked:(id)sender {
    NSAppleScript *as = [[NSAppleScript alloc] initWithSource:
        @"tell application \"Astra\" to tell window 1 to make new tab with properties {URL:\"chrome://settings/tabs\"}"];
    [as executeAndReturnError:nil];
}

- (void)onTabClicked:(AstraTabButton *)sender {
    NSInteger idx = sender.tabIndex;
    NSString *src = [NSString stringWithFormat:
        @"tell application \"Astra\" to tell window 1 to set active tab index to %ld", (long)idx];
    NSAppleScript *as = [[NSAppleScript alloc] initWithSource:src];
    [as executeAndReturnError:nil];
}

- (void)onTabCloseClicked:(NSButton *)sender {
    AstraTabButton *parent = (AstraTabButton *)[sender superview];
    if (!parent) return;
    NSInteger idx = parent.tabIndex;
    NSString *src = [NSString stringWithFormat:
        @"tell application \"Astra\" to close tab %ld of window 1", (long)idx];
    NSAppleScript *as = [[NSAppleScript alloc] initWithSource:src];
    [as executeAndReturnError:nil];
}

- (void)updateTabsWithTitles:(NSArray *)titles activeIndex:(NSInteger)activeIdx {
    if ([titles isEqualToArray:_lastTitles] && activeIdx == _lastActiveIndex) {
        return; // No change
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
static void update_window_layout(NSWindow *win) {
    if (!win) return;
    if (![[win className] isEqualToString:@"BrowserNativeWidgetWindow"]) return;

    NSView *cv = [win contentView];
    if (!cv) return;

    NSRect winBounds = [cv bounds];
    if (winBounds.size.width < 300 || winBounds.size.height < 300) return;

    BOOL isVertical = read_tab_orientation_setting();
    CGFloat sidebarWidth = isVertical ? read_sidebar_width_setting() : 220.0;
    CGFloat topTabHeight = 41.0;

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

        // Cover the top horizontal tabs above webContentsView
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

        // Query open tabs and update sidebar
        static NSTimeInterval s_last_query = 0;
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        if (now - s_last_query > 0.25) {
            s_last_query = now;
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
                    [titles addObject:st ? st : @"New Tab"];
                }
                [sidebarView updateTabsWithTitles:titles activeIndex:activeIdx];
            }
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
    [win setTitleVisibility:NSWindowTitleHidden];
    [win setTitle:@""];

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

    update_window_layout(win);
}

__attribute__((constructor))
static void install_astra_hook(void) {
    if (strcmp(getprogname(), "Astra_bin") != 0) return;

    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        NSWindow *win = note.object;
        configure_window(win);
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^(NSTimer * _Nonnull timer) {
            for (NSWindow *win in [NSApp windows]) {
                configure_window(win);
            }
        }];
    });
}
