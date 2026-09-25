#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>
#import <string.h>

// iPad Pro 13" M4 identifier reported to WeChat servers.
// Change this to another iPad model if needed.
#define FAKE_MACHINE        "iPad16,3"
#define FAKE_INTERNAL_MODEL "J720AP"
#define FAKE_DEVICE_NAME    "iPad"

static BOOL _isEnabled = YES;

// ---------------------------------------------------------------
// sysctlbyname hook
// Primary device fingerprint path used by WeChat for login protocol.
// ---------------------------------------------------------------
%hookf(int, sysctlbyname, const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen)
{
    int ret = %orig;
    if (!_isEnabled || ret != 0 || oldp == NULL || oldlenp == NULL || *oldlenp == 0) {
        return ret;
    }

    if (strcmp(name, "hw.machine") == 0) {
        strlcpy((char *)oldp, FAKE_MACHINE, *oldlenp);
    } else if (strcmp(name, "hw.model") == 0) {
        strlcpy((char *)oldp, FAKE_INTERNAL_MODEL, *oldlenp);
    }

    return ret;
}

// ---------------------------------------------------------------
// sysctl hook (legacy path, some code paths use raw sysctl)
// ---------------------------------------------------------------
%hookf(int, sysctl, int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen)
{
    int ret = %orig;
    if (!_isEnabled || ret != 0 || oldp == NULL || oldlenp == NULL || *oldlenp == 0) {
        return ret;
    }

    if (namelen == 2 && name[0] == CTL_HW && name[1] == HW_MACHINE) {
        strlcpy((char *)oldp, FAKE_MACHINE, *oldlenp);
    } else if (namelen == 2 && name[0] == CTL_HW && name[1] == HW_MODEL) {
        strlcpy((char *)oldp, FAKE_INTERNAL_MODEL, *oldlenp);
    }

    return ret;
}

// ---------------------------------------------------------------
// uname hook
// Secondary fingerprint path; WeChat reads utsname.machine.
// ---------------------------------------------------------------
%hookf(int, uname, struct utsname *name)
{
    int ret = %orig;
    if (!_isEnabled || ret != 0 || name == NULL) {
        return ret;
    }

    strlcpy(name->machine, FAKE_MACHINE, sizeof(name->machine));
    strlcpy(name->nodename, FAKE_DEVICE_NAME, sizeof(name->nodename));

    return ret;
}

// ---------------------------------------------------------------
// UIDevice hook
// WeChat checks [UIDevice model] for device type string.
// We intentionally do NOT hook userInterfaceIdiom so the iPhone
// UI layout remains intact.
// ---------------------------------------------------------------
%hook UIDevice
- (NSString *)model
{
    if (!_isEnabled) {
        return %orig;
    }
    return @"iPad";
}
%end

// ---------------------------------------------------------------
// Constructor
// ---------------------------------------------------------------
%ctor
{
    // Read toggle from CFPreferences (set via terminal or preference app)
    CFPreferencesAppSynchronize(CFSTR("com.user.wechatipadlogin"));
    Boolean keyExistsAndHasValidFormat = FALSE;
    BOOL prefValue = CFPreferencesGetAppBooleanValue(
        CFSTR("enabled"),
        CFSTR("com.user.wechatipadlogin"),
        &keyExistsAndHasValidFormat
    );
    if (keyExistsAndHasValidFormat) {
        _isEnabled = prefValue;
    }

    %init;
    NSLog(@"[WeChatIPadLogin] Loaded (enabled=%d, machine=%s)", _isEnabled, FAKE_MACHINE);
}
