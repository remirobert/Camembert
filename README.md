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

<hr>

<h1 align="center">Usage</h1>

First thing to do, is to initialise your sqlite3 database.
To do this you must make a call before any other use.
The database will be created automatically if it does not exist

```Swift
Camembert.initDataBase("dataBase.sql")
```
And **voila !**, you are ready to use Camembert.

You need now to create a class, matching with your table.
For doing that, you **MUST** inherit of **CamembertModel** class.
And use the **typealias** for create your rows.
You have to provide defaults values.

```Swift
typealias INTEGER = Int
typealias REAL = Float
typealias TEXT = String
typealias DATE_TIME = NSDate
typealias BIT = Bool
```

This is an example of a table Book:

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
    case SelectAll(OrderOperator, String)
    case CustomRequest(String)
    case Limit(Int, OrderOperator, String)
    case Between(Int, Int, OrderOperator, String)
    case Where(String, Operator, AnyObject, OrderOperator, String)
}
```

  - SelectAll(OrderOperator, String): will return all element in the table
  - CustomRequest(String): You can use there your own SQL request
  - Limit(Int, OrderOperator, String): will return a limited number of element
  - Between(Int, Int, OrderOperator, String): will return all the element between the interval
  - Where (ColumnName: String, Operator: Larger,equal..etc, Value, OrderOperator, ColumnToOrderBy): will return elements that value of Column specified matches the passed value ("Value")

```Swift
//display titles of the library (if order by is empty like in example below, order will be done on id column)
for currentElement in Book.select(selectRequest: Select.SelectAll, order: OrderOperator.Ascending, orderby: "") {
  println("current Book's title: \((currentElement as Book).title)")
}


```Swift
//display titles of the library
for currentElement in Book.select(selectRequest: Select.SelectAll, OrderOperator.Ascending, "") {
println("current Book's title: \((currentElement as Book).title)")
}

//reset currentPage
for currentElement in Book.select(selectRequest: Select.CustomRequest("SELECT * FROM Book WHERE currentPage > 0")) {
  (currentElement as Book).currentPage = 0
  (currentElement as Book).update()
}
```


```Swift
//How To us extension methods:
var myArray = Array<AnyObject>();
if let m_array = UserModel.select(selectRequest: Select.Where("FirstName", Operator.EqualsTo, "Hello", OrderOperator.Ascending, "LastName")){
    myArray = m_array.Take(10);
}

if let m_array = UserModel.select(selectRequest: Select.Where("FirstName", Operator.EqualsTo, "Hello", OrderOperator.Ascending, "")){
let myUserModel = (m_array.FirstOrDefault() as UserModel);
}

if let m_array = UserModel.select(selectRequest: Select.Where("FirstName", Operator.EqualsTo, "Hello", OrderOperator.Ascending, "")){
let myUserModel = (m_array.LastOrDefault() as UserModel);
}

if var m_array = UserModel.select(selectRequest: Select.Where("FirstName", Operator.EqualsTo, "Hello", OrderOperator.Ascending, "")){
myArray = m_array.TakeRange(1, offset: 10);
}

if var m_array = UserModel.select(selectRequest: Select.Where("FirstName", Operator.EqualsTo, "Hello", OrderOperator.Ascending, "")){
myArray = m_array.Union(Array())
}

let FirstName = (myArray as Array)[0].FirstName;
```


<h4 align="center">Get list of table</h4>

You get an array of all tables present in your database:

```Swift
let listTable = Camembert.getListTable()
```
<hr>

**_Camembert, will improve, here's the first version._**

<h1 align="center">Author</h1>
Rémi ROBERT, remirobert33530@gmail.com
<h1 align="center">Contributers List</h1>
Omar Bizreh, omar.bizreh@outlook.com

<h1 align="center">Licence</h1>
Camembert is available under the MIT license. See the LICENSE file for more info.
