/*
 * Tencent is pleased to support the open source community by making
 * WCDB available.
 *
 * Copyright (C) 2017 THL A29 Limited, a Tencent company.
 * All rights reserved.
 *
 * Licensed under the BSD 3-Clause License (the "License"); you may not use
 * this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 *       https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import XCTest
import WCDB

class TableTests: BaseTestCase {    
    var database: Database!
    
    override func setUp() {
        super.setUp()
        database = Database(withFileURL: self.recommendedPath)
    }    
    
    class BaselineObject: TableCodable, Named {
        var anInt32: Int32 = -1
        var anInt64: Int64 = 17626545782784
        var aString: String = "string"
        var aData: Data = "data".data(using: .ascii)!
        var aDouble: Double = 0.001
        
        required init() {}
        enum CodingKeys: String, CodingTableKey {
            typealias Root = BaselineObject
            case anInt32
            case anInt64
            case aString
            case aData
            case aDouble
            static let __objectRelationalMapping = TableBinding(CodingKeys.self)
            static var __columnConstraintBindings: [CodingKeys:ColumnConstraintBinding]? {
                return [.anInt32:ColumnConstraintBinding(isPrimary: true, orderBy: .Ascending, isAutoIncrement: true)]
            }
        }

        var isAutoIncrement: Bool = false
        var lastInsertedRowID: Int64 = 0
    }
    func testCreateTable() {
        //Give
        let tableName = BaselineObject.name
        //When
        XCTAssertNoThrow(try database.create(table: tableName, of: BaselineObject.self))
        //Then
        let optionalObject: Master? = WCDBAssertNoThrowReturned(try database.getObject(fromTable: Master.tableName, where: Master.CodingKeys.name==tableName))
        XCTAssertNotNil(optionalObject)
        let object = optionalObject!
        XCTAssertEqual(object.sql!, "CREATE TABLE \(tableName)(anInt32 INTEGER PRIMARY KEY ASC AUTOINCREMENT, anInt64 INTEGER, aString TEXT, aData BLOB, aDouble REAL)")
    }

    class IndexObject: TableCodable, Named {
        var variable: Int32 = 0
        required init() {}
        enum CodingKeys: String, CodingTableKey {
            typealias Root = IndexObject
            case variable
            static let __objectRelationalMapping = TableBinding(CodingKeys.self)
            static var __indexBindings: [IndexBinding.Subfix:IndexBinding]? {
                return ["_index":IndexBinding(indexesBy: CodingKeys.variable)]
            }
        }
    }
    func testCreateTableWithIndex() {
        //Give
        let tableName = IndexObject.name
        let indexName = tableName+"_index"
        //When
        XCTAssertNoThrow(try database.create(table: tableName, of: IndexObject.self))
        //Then
        let optionalObject: Master? = WCDBAssertNoThrowReturned(try database.getObject(fromTable: Master.tableName, where: Master.CodingKeys.name==indexName))
        XCTAssertNotNil(optionalObject)
        let object = optionalObject!
        XCTAssertEqual(object.sql!, "CREATE INDEX \(indexName) ON IndexObject(variable)")
    }

    class ConstraintObject: TableCodable, Named {
        var variable1: Int32 = 0
        var variable2: Int32 = 0
        
        required init() {}
        enum CodingKeys: String, CodingTableKey {
            typealias Root = ConstraintObject
            case variable1
            case variable2
            static let __objectRelationalMapping = TableBinding(CodingKeys.self)
            static var __tableConstraintBindings: [TableConstraintBinding.Name:TableConstraintBinding]? {
                return ["ConstraintObjectConstraint":MultiUniqueBinding(indexesBy: CodingKeys.variable1, CodingKeys.variable2)]
            }
        }
    }
    func testCreateTableWithConstraint() {
        //Give
        let tableName = ConstraintObject.name
        //When
        XCTAssertNoThrow(try database.create(table: tableName, of: ConstraintObject.self))
        //Then
        let optionalObject: Master? = WCDBAssertNoThrowReturned(try database.getObject(fromTable: Master.tableName, where: Master.CodingKeys.name==tableName))
        XCTAssertNotNil(optionalObject)
        let object = optionalObject!
        XCTAssertEqual(object.sql!, "CREATE TABLE \(tableName)(variable1 INTEGER, variable2 INTEGER, CONSTRAINT ConstraintObjectConstraint UNIQUE(variable1, variable2))")
    }

    class VirtualTableObject: TableCodable, Named {
        var variable1: Int32 = 0
        var variable2: Int32 = 0
        
        required init() {}
        enum CodingKeys: String, CodingTableKey {
            typealias Root = VirtualTableObject
            case variable1
            case variable2
            static let __objectRelationalMapping = TableBinding(CodingKeys.self)
            static var __virtualTableBinding: VirtualTableBinding? {
                return VirtualTableBinding(with: .fts3, and: ModuleArgument(with: .WCDB))
            }
        }
    }
    func testCreateVirtualTable() {
        //Give
        let tableName = VirtualTableObject.name
        database.setTokenizes(.WCDB)
        //When
        XCTAssertNoThrow(try database.create(virtualTable: tableName, of: VirtualTableObject.self))
        //Then
        let optionalObject: Master? = WCDBAssertNoThrowReturned(try database.getObject(fromTable: Master.tableName, where: Master.CodingKeys.name==tableName))
        XCTAssertNotNil(optionalObject)
        let object = optionalObject!
        XCTAssertEqual(object.sql!, "CREATE VIRTUAL TABLE VirtualTableObject USING fts3(variable1 INTEGER, variable2 INTEGER, tokenize=WCDB)")
    }
    
    class AutoFitBaseLineObject: TableCodable, Named {
        var anInt32: Int32 = -1
        var anInt64: Int64 = 17626545782784
        var aString: String = "string"
        var aData: Data = "data".data(using: .ascii)!
        var aDouble: Double = 0.001
        var newColumn: Int = 0
        
        required init() {}
        var isAutoIncrement: Bool = false
        var lastInsertedRowID: Int64 = 0
        enum CodingKeys: String, CodingTableKey {
            typealias Root = AutoFitBaseLineObject
            case anInt32
            case anInt64
            case aString
            case aData
            case aDouble
            case newColumn
            static let __objectRelationalMapping = TableBinding(CodingKeys.self)
            static var __columnConstraintBindings: [CodingKeys:ColumnConstraintBinding]? {
                return [.anInt32:ColumnConstraintBinding(isPrimary: true, orderBy: .Ascending, isAutoIncrement: true)]
            }
        }
    }
    func testCreateTableAutoFitORM() {
        //Give
        let tableName = AutoFitBaseLineObject.name
        XCTAssertNoThrow(try database.create(table: tableName, of: BaselineObject.self))
        //Then
        XCTAssertNoThrow(try database.create(table: tableName, of: AutoFitBaseLineObject.self))
        let optionalObject: Master? = WCDBAssertNoThrowReturned(try database.getObject(fromTable: Master.tableName, where: Master.CodingKeys.name==tableName))
        XCTAssertNotNil(optionalObject)
        let object = optionalObject!
        XCTAssertEqual(object.sql!, "CREATE TABLE \(tableName)(anInt32 INTEGER PRIMARY KEY ASC AUTOINCREMENT, anInt64 INTEGER, aString TEXT, aData BLOB, aDouble REAL, newColumn INTEGER)")
    }
    
    func testDropTable() {
        //Give
        let tableName = BaselineObject.name
        //When
        XCTAssertNoThrow(try database.create(table: tableName, of: BaselineObject.self))
        XCTAssertNoThrow(try database.drop(table: tableName))
        //Then
        let optionalObject: Master? = WCDBAssertNoThrowReturned(try database.getObject(fromTable: Master.tableName, where: Master.CodingKeys.name==tableName))
        XCTAssertNil(optionalObject)
    }

    func testDropIndex() {
        //Give
        let tableName = IndexObject.name
        let indexName = tableName+"_index"
        //When
        XCTAssertNoThrow(try database.create(table: tableName, of: IndexObject.self))
        XCTAssertNoThrow(try database.drop(index: indexName))
        //Then
        let optionalObject: Master? = WCDBAssertNoThrowReturned(try database.getObject(fromTable: Master.tableName, where: Master.CodingKeys.name==indexName))
        XCTAssertNil(optionalObject)
    }

    func testManuallyCreateTable() {
        //Give
        let tableName = BaselineObject.name
        let tableConstraint = TableConstraint(named: "BaselineObjectConstraint").check((BaselineObject.CodingKeys.anInt32)>0)
        let def1 = (BaselineObject.CodingKeys.anInt32).asDef(with: .Integer32)
        let def2 = (BaselineObject.CodingKeys.anInt64).asDef(with: .Integer64)
        //When
        XCTAssertNoThrow(try database.create(table: tableName, with: def1, def2, and: [tableConstraint]))
        let optionalObject: Master? = WCDBAssertNoThrowReturned(try database.getObject(fromTable: Master.tableName, where: Master.CodingKeys.name==tableName))
        XCTAssertNotNil(optionalObject)
        let object = optionalObject!
        XCTAssertEqual(object.sql!, "CREATE TABLE \(tableName)(anInt32 INTEGER, anInt64 INTEGER, CONSTRAINT BaselineObjectConstraint CHECK(anInt32 > 0))")
    }
    
    func testManuallyAddColumn() {
        //Give
        let tableName = BaselineObject.name
        let def = Column(named: "newColumn").asDef(with: .Integer32)
        //When
        XCTAssertNoThrow(try database.create(table: tableName, of: BaselineObject.self))
        XCTAssertNoThrow(try database.addColumn(with: def, forTable: tableName))
        //Then
        let optionalObject: Master? = WCDBAssertNoThrowReturned(try database.getObject(fromTable: Master.tableName, where: Master.CodingKeys.name==tableName))
        XCTAssertNotNil(optionalObject)
        let object = optionalObject!
        XCTAssertEqual(object.sql!, "CREATE TABLE \(tableName)(anInt32 INTEGER PRIMARY KEY ASC AUTOINCREMENT, anInt64 INTEGER, aString TEXT, aData BLOB, aDouble REAL, newColumn INTEGER)")
    }
    
    
    func testManuallyCreateIndex() {
        //Give
        let tableName = BaselineObject.name
        let indexName = tableName+"_index"
        let index1 = (BaselineObject.CodingKeys.aString).asIndex()
        let index2 = (BaselineObject.CodingKeys.aDouble).asIndex()
        //When
        XCTAssertNoThrow(try database.create(table: tableName, of: BaselineObject.self))
        XCTAssertNoThrow(try database.create(index: indexName, with: index1, index2, forTable: tableName))
        //Then
        let optionalObject: Master? = WCDBAssertNoThrowReturned(try database.getObject(fromTable: Master.tableName, where: Master.CodingKeys.name==indexName))
        XCTAssertNotNil(optionalObject)
        let object = optionalObject!
        XCTAssertEqual(object.sql!, "CREATE INDEX \(indexName) ON \(tableName)(aString, aDouble)")
    }
    
    func testGetTable() {
        //Give
        let tableName = BaselineObject.name
        var table: Table<BaselineObject>? = nil
        //When
        table = WCDBAssertNoThrowReturned(try database.getTable(named: tableName))
        XCTAssertNil(table)
        XCTAssertNoThrow(try database.create(table: tableName, of: BaselineObject.self))
        //Then
        table = WCDBAssertNoThrowReturned(try database.getTable(named: tableName))
        XCTAssertNotNil(table)
    }
}