if (window.googletag && window.googletag.apiReady) {
    googletag.cmd.push(function() {
        googletag.pubads().addEventListener('impressionViewable', function(event) {
            window.adsViewableTime = window.adsViewableTime || Date.now()
        });
        googletag.pubads().addEventListener('slotRenderEnded', function(event) {
            window.adsShownTime = window.adsShownTime || Date.now()
        })
    })
}
window.addEventListener('load', function() {
    if (window.newrelic && window.performance && window.performance.timing) {
        if (window.chrome) {
            var loadTimes = window.chrome.loadTimes();
            if (loadTimes && loadTimes.firstPaintTime && loadTimes.startLoadTime) {
            	window.newrelic.setCustomAttribute('FirstPaint', loadTimes.firstPaintTime - loadTimes.startLoadTime);
            }
        }
        window.newrelic.setCustomAttribute('AdsViewableTime', (window.adsViewableTime - performance.timing.navigationStart) / 1000.0);
        window.newrelic.setCustomAttribute('AdsShownTime', (window.adsShownTime - performance.timing.navigationStart) / 1000.0);
        window.newrelic.setCustomAttribute('PerceivedLoadTime', (performance.timing.domContentLoadedEventEnd - performance.timing.navigationStart) / 1000.0);
    }
}, false)