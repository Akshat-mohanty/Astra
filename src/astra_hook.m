#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static void configure_window(NSWindow *win) {
    if (!win) return;
    // Hide window title text and keep titlebar area sleek
    [win setTitleVisibility:NSWindowTitleHidden];
    [win setTitle:@""];

    // Ensure window is visible on an active display
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

__attribute__((constructor))
static void install_astra_hook(void) {
    if (strcmp(getprogname(), "Astra_bin") != 0) return;

    // Hook window creation and configure titlebar
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        NSWindow *win = note.object;
        configure_window(win);
    }];

    // Periodic timer to keep title hidden and window placed properly
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
            for (NSWindow *win in [NSApp windows]) {
                configure_window(win);
            }
        }];
    });
}
