# TestAppPower: Integrating PowerMetricsKit into a sample app

@Metadata {
    @PageKind(sampleCode)
    @CallToAction(url: "https://github.com/Androp0v/TestAppPower", purpose: download)
}

Integrate PowerMetricsKit into a sample SwiftUI app.

## Overview

The sample app combines PowerMetricsKit's ``PowerWidgetView`` with a heavy, compute-intensive numerical simulation designed to skyrocket the power usage of the CPU for testing purposes.

## The simulation

To load the CPU, the app uses a Runge-Kutta numerical ordinary differential equation (ODE) solver to integrate the movement of several particles in a system of equations that creates a Lorentz attractor.
