# CV using SwiftUI + Combine

Follows the same project structure as [IRShowcase](https://github.com/iruleonu/IRShowcase). 

## Uses

* Swift
* SwiftUI
* Combine

## Misc
* It has a ObservableObject ViewModel that's going to be connected to the SwiftUI view as a @ObservedObject, essentially serving as a State. The presenter has the logic.

* On RootCoordinatorBuilder you'll see it injects the two layers (APIService and Persistence) into the main screen presenter (DummyProductsViewPresenterImpl)
On the same RootCoordinatorBuilder there's a second entry point where you can see an example with two DataProviders that can be used with a distinct configuration. It's even possible to make it a hybrid data provider where it fetches both locally and remotely in case of errors.

* There's tests for logic, providers and UI tests.

* DummyProductsListViewPresenterTests has tests making sure if there's valid results locally then there's no remote fetch

* There's no pagination support for now 
