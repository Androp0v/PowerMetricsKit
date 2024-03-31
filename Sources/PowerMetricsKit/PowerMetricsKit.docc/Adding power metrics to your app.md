# Adding power metrics to your app

Measure energy used by your app.

## Overview

There are two main ways of using `PowerMetricsKit`: by adding a ``PowerWidgetView` to your app, or by calling the sampling methods from your own code.

### Power widget

![PowerWidgetView](PowerWidgetView)

`PowerMetricsKit` can be used simply by adding the built-in component ``PowerWidgetView`` to any SwiftUI view hierarchy:
```swift
struct ContentView: View {
    var body: some View {
        PowerWidgetView()
    }
}
```
By default, ``PowerWidgetView`` will use the pid of the parent process, as sampling the pid of a different process requires special entitlements.


### Manual sampling

To interact with `PowerMetricsKit`, you'll need to create an instance of ``SampleThreadsManager``, and manually start the sampling process. To sample the parent process (sampling the pid of a different process requires special entitlements) you can use `ProcessInfo.processInfo.processIdentifier`:
```swift
let sampleManager = SampleThreadsManager()
let pid = ProcessInfo.processInfo.processIdentifier
await sampleManager.startSampling(pid: pid)
```
After this, you can retrieve information about the target pid from the ``SampleThreadsManager`` instance. For example, by accessing the `currentThreadCount` or `totalEnergyUsage` properties.

To stop the sampling, do:
```swift
sampleManager.stopSampling()
```
