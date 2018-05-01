# SampleCodeiOS

This class is **ViewControllers** class, which manage screen with a list of store products.

Content elements are stored in **CollectionView**. Entities that represent each product are reflected in the corresponding class, which is an array of screen content, which is controlled by this class.

Some actions and information are moved into another separated classes. For example information about the presence of compounds with internet **StoreBaseViewController** receives from **RequestManager**.

The implementation of some controls, such buttons for content screening, designed as a single subclass a **UIView**, which reports on the options conveniently selected by the user.

Developed using **Objective-C, Xcode 8**
