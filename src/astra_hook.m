#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static void open_new_astra_instance(void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        system("open -n -a /Applications/Astra.app &");
    });
}

@interface AstraMenuTarget : NSObject
- (void)openAstraTab:(id)sender;
@end

@implementation AstraMenuTarget
- (void)openAstraTab:(id)sender {
    open_new_astra_instance();
}
@end

static AstraMenuTarget *g_menu_target = nil;
static void (*orig_sendEvent)(id, SEL, NSEvent *);

static void my_sendEvent(id self, SEL _cmd, NSEvent *event) {
    if ([event type] == NSEventTypeKeyDown) {
        NSUInteger flags = [event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
        if (flags == NSEventModifierFlagCommand) {
            NSString *chars = [event charactersIgnoringModifiers];
            if ([chars isEqualToString:@"t"] || [chars isEqualToString:@"n"]) {
                open_new_astra_instance();
                return;
            }
        }
    }
    orig_sendEvent(self, _cmd, event);
}

static void configure_window(NSWindow *win) {
    if (!win) return;
    // Hide the title text and any IP/origin from the top center
    [win setTitleVisibility:NSWindowTitleHidden];
    [win setTitle:@""];

    // Ensure window is visible on an active display (avoiding phantom off-screen coordinates)
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

    g_menu_target = [[AstraMenuTarget alloc] init];

    // 1. Hook keyboard events to intercept Cmd+T and Cmd+N
    Class app_cls = [NSApplication class];
    Method m = class_getInstanceMethod(app_cls, @selector(sendEvent:));
    if (m) {
        orig_sendEvent = (void (*)(id, SEL, NSEvent *))method_getImplementation(m);
        method_setImplementation(m, (IMP)my_sendEvent);
    }

    // 2. Hook window creation and configure titlebar
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        NSWindow *win = note.object;
        configure_window(win);
    }];

    // 3. Periodic timer to keep title hidden and patch menu items
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^(NSTimer * _Nonnull timer) {
            for (NSWindow *win in [NSApp windows]) {
                configure_window(win);
            }
            NSMenu *mainMenu = [NSApp mainMenu];
            if (mainMenu) {
                for (NSMenuItem *item in [mainMenu itemArray]) {
                    if ([item hasSubmenu]) {
                        for (NSMenuItem *subItem in [[item submenu] itemArray]) {
                            if ([[subItem keyEquivalent] isEqualToString:@"t"] || [[subItem keyEquivalent] isEqualToString:@"n"]) {
                                [subItem setTarget:g_menu_target];
                                [subItem setAction:@selector(openAstraTab:)];
                            }
                        }
                    }
                }
            }
        }];
    });
}
