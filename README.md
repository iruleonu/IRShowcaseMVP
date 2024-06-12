[![ios with xcode 15](https://github.com/iruleonu/IRShowcaseMVP/actions/workflows/ios.yml/badge.svg)](https://github.com/iruleonu/IRShowcaseMVP/actions/workflows/ios.yml)

# Showcase using SwiftUI + Combine

Follows the same project structure as [IRShowcase](https://github.com/iruleonu/IRShowcase). 

## Uses

* Swift
* SwiftUI
* Combine

## Architecture layers naming
You can look at the ViewModel as the Interactor and the ObservableObject within the ViewModel as the Presenter. The view in SwiftUI sends actions to the ViewModel (the Interactor layer) and reads the State from the ObservableObject within the ViewModel (the Presenter layer)

## Misc
* It has a ObservableObject that's going to be connected to the SwiftUI view as a @ObservedObject, essentially serving as a State. The viewModel has the logic.

* FooViewModel is a protocol that's marked with "// sourcery: AutoMockable" so that it can be mocked in the tests. The implementation goes into FooViewModelImpl.

* On RootCoordinatorBuilder you'll see it injects the two layers (APIService and Persistence) into the main screen presenter (DummyProductsViewViewModelImpl)
On the same RootCoordinatorBuilder there's a second entry point where you can see an example with two DataProviders that can be used with a distinct configuration. 
It's possible to make it a hybrid data provider where it fetches both locally and remotely in case of a local fetch error.

* There's tests for logic, providers and UI tests.

* DummyProductsListViewModelTests has tests making sure if there's valid results locally then there's no remote fetch
