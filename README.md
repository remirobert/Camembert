<p align="center">
  <img src ="https://raw.githubusercontent.com/remirobert/Camembert/master/ressources/CamembertLogo.png"/>
  <h1 align="center">Camembert</h1>
</p>

Camembert is a toolkit written in **swift**, for using sqlite3 easier. Is is available for **OSX** and **iOS**.
</br>
<h1 align="center">Installation</h1>

First you need to add a bridging-header to your project.
If it is already set to copy the contents of Bridging-header.h in yours.

```Objective-C
#import <UIKit/UIKit.h>
#import "sqlite3.h"

BOOL camembertExecSqlite3(void *ptrSqlite3, const char *request);
id camembertCreateObject(NSString *nameClass);
```

If you need to add one, follow these instructions:

- Go into the **settings** of your project in the category **build setting**.
- Search **Objective-C Bridging Header** with the search bar.
- Add the following line : **${YOURPROJ}Bridging-Header.h**
- Then copy the **Bridging-header.h** file, in your project.

When the Bridging Header is created, simply copy the files *.m and *.swift from the directory sources.


<h1 align="center">Usage</h1>

First thing to do, is to initialise your sqlite3 database.
To do this you must make two calls before any other use.

```Swift
Camembert.initDataBase("dataBase.sql")
// ...
Camembert.closeDataBase()
```
And **voila !**, you are ready to use Camembert.

You need now to create a class, that corespond to your table.
For doing that, you **MUST** inherit of **CamembertModel** class.
And use the **typealias** for create your rows.
You have to provide defaults values.

```Swift
typealias INTEGER = Int
typealias REAL = Float
typealias TEXT = String
```

This is a example of my table Book:

```Objective-C
class Book :CamembertModel {
    var title :TEXT = ""
    var numberPage :INTEGER = 0
    var currentPage :INTEGER = 0
}
```
_The Book class corresponds to model, of my table Book in my database._


<h4 align="center">Create a new element</h4>

```Swift
var newBook = Book()
newBook.title = "La Fontaine : Fables"
newBook.numberPage = 544
newBook.currentPage = 43
newBook.push()
```
As you can see for creating a new element, you just need to create a new object, and call the push method.
If the table doest not exist yet, it will be created automatly.


<h4 align="center">Update element</h4>

```swift
var newBook = Book()
newBook.title = "La Fontaine : Fables"
newBook.numberPage = 544
newBook.currentPage = 43
newBook.push()

//...

newBook.currentPage = 103
newBook.update()
```
To change something in a existing element, you just need to call the **update** method.
To do this you need to have an object already created.
Or you can use the constructor with a specific element based on the **ID**:

```swift
var book = Book(id: 4)
book.currentPage = 103
book.update()
```

<h4 align="center">Remove element</h4>

```swift
var newBook = Book()
newBook.title = "La Fontaine : Fables"
newBook.numberPage = 544
newBook.currentPage = 43
newBook.push()

//...

newBook.remove()

var book = Book(id: 4)
book.remove()
```
Just call the **remove** method, for remove the element in the Table.


<h4 align="center">Get the number of elements in a table</h4>

```Swift
var numberElement :Int = Book.numberElement()
println("number books : \(numberElement)")
```


<h4 align="center">Get list of elements in a table</h4>

```Swift
//display title of the library
for currentElement :AnyObject in Camembert.getObjectsWithQuerry("SELECT * from Book;", table: "Book") {
  println("current book : \((currentElement as Book).title)")
}

//reset currentPage
var elements = Camembert.getObjectsWithQuerry("SELECT * from Book WHERE numberPage >= 100;", table: "Book")
for currentElement in elements {
  (currentElement as Book).currentPage = 0
  (currentElement as Book).update()
}

//remove all element
for currentElement :AnyObject in Camembert.getObjectsWithQuerry("SELECT * from Book;", table: "Book") {
  (currentElement as Book).remove()
}
```

To get an accurate list of elements in a table, you must provide a **SQL query**. Above all, the **name of the table**, which is used to create objects automatically. You absolutely have a **class** corespondant to your table, as in the examples above.

The objects list, is **universal** (AnyObject), but all objects are created from your class, so you can cast it.

**_Camembert, will improve, here's the first version._**

<h1 align="center">Author</h1>
Rémi ROBERT, remirobert33530@gmail.com

<h1 align="center">Licence</h1>
Camembert is available under the MIT license. See the LICENSE file for more info.
