#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

@implementation NSApplication (AstraHook)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = [NSApplication class];
        Method orig = class_getInstanceMethod(cls, @selector(sendAction:to:from:));
        Method swiz = class_getInstanceMethod(cls, @selector(astra_sendAction:to:from:));
        method_exchangeImplementations(orig, swiz);
    });
}

- (BOOL)astra_sendAction:(SEL)action to:(id)target from:(id)sender {
    if ([sender isKindOfClass:[NSMenuItem class]]) {
        NSMenuItem *item = (NSMenuItem *)sender;
        NSString *title = [item title];
        NSString *key = [item keyEquivalent];
        NSUInteger mask = [item keyEquivalentModifierMask];

        BOOL isCmdT = [key isEqualToString:@"t"] && (mask & NSEventModifierFlagCommand);
        BOOL isCmdN = [key isEqualToString:@"n"] && (mask & NSEventModifierFlagCommand);
        BOOL isNewTab = title && [title localizedCaseInsensitiveContainsString:@"New Tab"];
        BOOL isNewWindow = title && [title localizedCaseInsensitiveContainsString:@"New Window"] && ![title localizedCaseInsensitiveContainsString:@"Incognito"];

        if (isCmdT || isCmdN || isNewTab || isNewWindow) {
            system("open -n -a /Applications/Astra.app &");
            return YES;
        }
    }
    return [self astra_sendAction:action to:target from:sender];
}

@end
