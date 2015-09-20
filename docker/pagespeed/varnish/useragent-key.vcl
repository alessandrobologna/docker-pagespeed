# from https://github.com/pagespeed/mod_pagespeed/blob/master/install/debug_conf.v4.vcl
# Block 2: Define a key based on the User-Agent which can be used for hashing.
# Also set the PS-CapabilityList header for PageSpeed server to respect.
sub generate_user_agent_based_key {
    # Define placeholder PS-CapabilityList header values for large and small
    # screens with no UA dependent optimizations. Note that these placeholder
    # values should not contain any of ll, ii, dj, jw or ws, since these
    # codes will end up representing optimizations to be supported for the
    # request.
    set req.http.default_ps_capability_list_for_large_screens = "LargeScreen.SkipUADependentOptimizations:";
    set req.http.default_ps_capability_list_for_small_screens = "TinyScreen.SkipUADependentOptimizations:";

    # As a fallback, the PS-CapabilityList header that is sent to the upstream
    # PageSpeed server should be for a large screen device with no browser
    # specific optimizations.
    set req.http.PS-CapabilityList = req.http.default_ps_capability_list_for_large_screens;

    # Cache-fragment 1: Desktop User-Agents that support lazyload_images (ll),
    # inline_images (ii) and defer_javascript (dj).
    # Note: Wget is added for testing purposes only.
    if (req.http.User-Agent ~ "(?i)Chrome/|Firefox/|Trident/6\.|Safari|Wget") {
      set req.http.PS-CapabilityList = "ll,ii,dj:";
    }
    # Cache-fragment 2: Desktop User-Agents that support lazyload_images (ll),
    # inline_images (ii), defer_javascript (dj), webp (jw) and lossless_webp
    # (ws).
    if (req.http.Accept ~ "webp") {
      set req.http.PS-CapabilityList = "ll,ii,dj,jw,ws:";
    }
    # Cache-fragment 3: This fragment contains (a) Desktop User-Agents that
    # should not map to fragments 1 or 2 and (b) all tablet User-Agents. These
    # will only get optimizations that work on all browsers and use image
    # compression qualities applicable to large screens. Note that even tablets
    # that are capable of supporting inline or webp images, for e.g. Android
    # 4.1.2, will not get these advanced optimizations.
    if (req.http.User-Agent ~ "(?i)Firefox/[1-2]\.|bot|Yahoo!|Ruby|RPT-HTTPClient|(Google \(\+https\:\/\/developers\.google\.com\/\+\/web\/snippet\/\))|Android|iPad|TouchPad|Silk-Accelerated|Kindle Fire") {
      set req.http.PS-CapabilityList = req.http.default_ps_capability_list_for_large_screens;
    }
    # Cache-fragment 4: Mobiles and small screen tablets will use image
    # compression qualities applicable to small screens, but all other
    # optimizations will be those that work on all browsers.
    if (req.http.User-Agent ~ "(?i)Mozilla.*Android.*Mobile*|iPhone|BlackBerry|Opera Mobi|Opera Mini|SymbianOS|UP.Browser|J-PHONE|Profile/MIDP|portalmmm|DoCoMo|Obigo|Galaxy Nexus|GT-I9300|GT-N7100|HTC One|Nexus [4|7|S]|Xoom|XT907") {
      set req.http.PS-CapabilityList = req.http.default_ps_capability_list_for_small_screens;
    }
    # Remove placeholder header values.
    unset req.http.default_ps_capability_list_for_large_screens;
    unset req.http.default_ps_capability_list_for_large_screens;
}
