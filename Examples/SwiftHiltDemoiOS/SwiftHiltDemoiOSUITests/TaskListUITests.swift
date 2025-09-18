import XCTest

final class TaskListUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["UITEST_INMEMORY"] = "1"
        app.launch()
    }

    func testQuickAddToggleDelete() {
        let field = app.textFields["quickAddField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("UI Task 1")

        let add = app.buttons["quickAddButton"]
        XCTAssertTrue(add.exists)
        add.tap()

        let cell = app.cells.containing(.staticText, identifier: "UI Task 1").element
        XCTAssertTrue(cell.waitForExistence(timeout: 5))

        // Toggle complete
        let toggle = cell.buttons["toggle"]
        XCTAssertTrue(toggle.exists)
        toggle.tap()

        // Switch to Completed filter via the top-right menu and verify
        let filterMenu = app.buttons["filterMenuButton"]
        XCTAssertTrue(filterMenu.waitForExistence(timeout: 3))
        filterMenu.tap()
        let completed = app.buttons["Completed"]
        XCTAssertTrue(completed.waitForExistence(timeout: 2))
        completed.tap()
        XCTAssertTrue(app.staticTexts["UI Task 1"].waitForExistence(timeout: 2))

        // Delete via swipe
        let completedCell = app.cells.containing(.staticText, identifier: "UI Task 1").element
        XCTAssertTrue(completedCell.exists)
        completedCell.swipeLeft()
        let deleteBtn = app.buttons["Delete"]
        XCTAssertTrue(deleteBtn.waitForExistence(timeout: 2))
        deleteBtn.tap()

        XCTAssertFalse(app.staticTexts["UI Task 1"].waitForExistence(timeout: 1))
    }

    func testCreateViaDetailAndEdit() {
        let create = app.buttons["createTaskButton"]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        create.tap()

        let titleField = app.textFields["titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("UI Task 2")

        let save = app.buttons["saveButton"]
        XCTAssertTrue(save.exists)
        save.tap()

        let cell = app.cells.containing(.staticText, identifier: "UI Task 2").element
        XCTAssertTrue(cell.waitForExistence(timeout: 5))

        // Open detail and edit title
        cell.tap()
        let editTitle = app.textFields["titleField"]
        XCTAssertTrue(editTitle.waitForExistence(timeout: 5))
        editTitle.tap()
        // select all and replace
        let selectAll = app.menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 1) { selectAll.tap() }
        app.typeText("UI Task 2 Edited")
        app.buttons["saveButton"].tap()

        XCTAssertTrue(app.staticTexts["UI Task 2 Edited"].waitForExistence(timeout: 5))
    }

    func testSearch() {
        let field = app.textFields["quickAddField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap(); field.typeText("Buy milk")
        app.buttons["quickAddButton"].tap()
        field.tap(); field.typeText("Email Alice")
        app.buttons["quickAddButton"].tap()

        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Email")

        XCTAssertTrue(app.staticTexts["Email Alice"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Buy milk"].waitForExistence(timeout: 1))
    }

    func testDetailSetDueDateAndPriority() {
        let create = app.buttons["createTaskButton"]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        create.tap()

        let titleField = app.textFields["titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap(); titleField.typeText("With Due + Urgent")

        let dueToggle = app.switches["hasDueDateToggle"]
        XCTAssertTrue(dueToggle.waitForExistence(timeout: 3))
        if dueToggle.value as? String == "0" { dueToggle.tap() }

        // Choose priority Urgent
        let urgent = app.segmentedControls.buttons["Urgent"]
        if urgent.waitForExistence(timeout: 2) { urgent.tap() }

        app.buttons["saveButton"].tap()

        let cell = app.cells.containing(.staticText, identifier: "With Due + Urgent").element
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        XCTAssertTrue(cell.staticTexts["URGENT"].exists)
        XCTAssertTrue(cell.staticTexts.matching(identifier: "dueLabel").element.exists)
    }

    func testFiltersCompletedOnly() {
        let field = app.textFields["quickAddField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap(); field.typeText("Task A")
        app.buttons["quickAddButton"].tap()
        field.tap(); field.typeText("Task B")
        app.buttons["quickAddButton"].tap()

        // Complete Task A
        let cellA = app.cells.containing(.staticText, identifier: "Task A").element
        XCTAssertTrue(cellA.waitForExistence(timeout: 3))
        let toggleA = cellA.buttons["toggle"]
        toggleA.tap()

        // Completed filter
        let filterMenu = app.buttons["filterMenuButton"]
        XCTAssertTrue(filterMenu.waitForExistence(timeout: 2))
        filterMenu.tap()
        app.buttons["Completed"].tap()
        XCTAssertTrue(app.staticTexts["Task A"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Task B"].waitForExistence(timeout: 1))

        // All filter shows both
        filterMenu.tap()
        app.buttons["All"].tap()
        XCTAssertTrue(app.staticTexts["Task A"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Task B"].waitForExistence(timeout: 2))
    }

    func testSaveDisabledWhenEmptyTitle() {
        let create = app.buttons["createTaskButton"]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        create.tap()

        let save = app.buttons["saveButton"]
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        XCTAssertFalse(save.isEnabled)

        let titleField = app.textFields["titleField"]
        titleField.tap(); titleField.typeText("Non empty")
        XCTAssertTrue(save.isEnabled)

        // Cancel to exit
        app.buttons["Cancel"].tap()
    }
}
