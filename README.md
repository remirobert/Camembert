<p align="center">
  <img src ="https://raw.githubusercontent.com/remirobert/Camembert/master/ressources/CamembertLogo.png"/>
  <h1 align="center">Camembert</h1>
</p>

Camembert is a toolkit written in **swift**, for using sqlite3 easier. Is is available for **OSX** and **iOS**.
</br>
<h1 align="center">Installation</h1>

First you need to add a **bridging-header** to your project.
If it is already set, import Camembert.

```Objective-C
#import "Camembert.h"
```

If you need to add one, follow these instructions:

- Create a new header file.
- Go into the **settings** of your project in the category **build setting**.
- Search **Objective-C Bridging Header** with the search bar.
- Add the following line : **headerFileName.h**
- Then import ```#import "Camembert.h"``` in your header file.

When the Bridging Header is created, simply copy the files *.m and *.swift from the directory sources.


<h1 align="center">Usage</h1>

First thing to do, is to initialise your sqlite3 database.
To do this you must make two calls before any other use.
It will create for you the database in the document directory, if it don't exist yet.

```Swift
Camembert.initDataBase("dataBase.sql")
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

This is a example of a table Book:

```Objective-C
class Book :CamembertModel {
    var title :TEXT = ""
    var numberPage :INTEGER = 0
    var currentPage :INTEGER = 0
}
```
_The Book class corresponds to model, and will be associated with the table Book in the database._


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

For select elements in the tables, you need to perform a request.
For doing this easily you can use the enum Select.

```Swift
enum Select {
    case SelectAll
    case CustomRequest(String)
    case Limit(Int)
    case Between(Int, Int)
}
```

  - SelectAll: will return all element in the table
  - CustomRequest(String): You can use there your own SQL request
  - Limit(Int): will return a limited number of element
  - Between(Int, Int): will return all the element between the interval

```Swift
//display titles of the library
for currentElement in Book.select(selectRequest: Select.SelectAll, classModel: Book.self) {
  println("current Book's title: \((currentElement as Book).title)")
}

//reset currentPage
for currentElement in Book.select(selectRequest: Select.CustomRequest("SELECT * FROM Book WHERE currentPage > 0"), classModel: Book.self) {
  (currentElement as Book).currentPage = 0
  (currentElement as Book).update()
}
```

<h4 align="center">Get list of table</h4>

You get an array of all tables present in your database:

```Swift
let listTable = Camembert.getListTable()
```

To get an accurate list of elements in a table, you must provide a Select request. Above all, the **class model**, which is used to create objects automatically. You absolutely have a **class** corespondant to your table, as in the examples above.

The objects list, is **universal** (AnyObject), but all objects are created from your class.

**_Camembert, will improve, here's the first version._**

<h1 align="center">Author</h1>
Rémi ROBERT, remirobert33530@gmail.com

<h1 align="center">Licence</h1>
Camembert is available under the MIT license. See the LICENSE file for more info.
