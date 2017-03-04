//
//  ViewController.swift
//  Kiddo Events
//
//  Created by Filiz Kurban on 3/1/17.
//  Copyright © 2017 Filiz Kurban. All rights reserved.
//

import Cocoa
import Parse

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var eventTitle: NSTextField!
    @IBOutlet weak var location: NSTextField!
    @IBOutlet weak var addDateButton: NSButton!
    @IBOutlet weak var datePicker: NSDatePicker!
    @IBOutlet weak var dateListTable: NSTableView!
    @IBOutlet weak var doneButton: NSButton!

    @IBOutlet weak var isPopular: NSButton!
    @IBOutlet weak var isActive: NSButton!
    var dates = [Date]() {
        didSet {
            dateListTable.reloadData()
        }
    }
    @IBOutlet weak var eventPriceField: NSTextField!
    @IBOutlet weak var eventEndTimePicker: NSDatePicker!
    @IBOutlet weak var eventStartTimePicker: NSDatePicker!

    var dateFormatter = DateFormatter()

    private var testData = [String: [String: Any]]()

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
                   }
    }

    override func viewDidLoad() {
         super.viewDidLoad()
        datePicker.dateValue = Date()
        dateListTable.delegate = self
        dateListTable.dataSource = self
    }



    func addDate(_ sender: Any) {
        let date = datePicker.dateValue
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.day, .year, .month], from: date)
        let dateWithSetComponents = calendar.date(from: components)!
        dates.append(dateWithSetComponents)
    }

    @IBAction func doneButtonClicked(_ sender: Any) {
        createTestData()
        saveTestData()
        if validateFields() {

        }

    }

    @IBAction func allDayEventPicked(_ sender: NSButton) {
        switch sender.state {
        case NSOnState:
            eventStartTimePicker.isEnabled = false
            eventEndTimePicker.isEnabled = false
        case NSOffState:
            eventStartTimePicker.isEnabled = true
            eventEndTimePicker.isEnabled = true
        default:
            print("should not hit here")
        }

    }

    @IBAction func freeEventPicked(_ sender: NSButton) {
        switch sender.state {
        case NSOnState:
            eventPriceField.isEnabled = false
        case NSOffState:
            eventPriceField.isEnabled = true
        default:
            print("should not hit here")
        }
    }

    private func validateFields() -> Bool {
        //enter validation logic here.
        return true
    }

    private func createTestData() {
        var data = [String: Any]()
        data["title"] = "Test Time"
        var allEventDates = [Date]()
//        allEventDates.append(DateUtil.shared.createDate(from: "03-01-2017"))
//        allEventDates.append(DateUtil.shared.createDate(from: "03-02-2017"))
//        allEventDates.append(DateUtil.shared.createDate(from: "03-03-2017"))
//        allEventDates.append(DateUtil.shared.createDate(from: "03-04-2017"))
        data["allEventDates"] = self.dates
        data["startDate"] = Date()
        data["endDate"] = Date()
        data["allDay"] = false
        data["startTime"] = "9:30 AM"
        data["endTime"] = "12:00 AM"
        data["free"] = false
        data["price"] = "0-3 FREE / 4 -12 16.95 / 13 and older 24.95"
        data["originalEventURL"] = "http://www.seattleaquarium.org/"
        data["location"] = "Seattle Aquarium"
        data["locationHours"] = ""
        data["address"] = "1483 Alaskan Way, Seattle, WA 98101"
        data["description"] = "From dressing up like a wolf eel to fish-print painting and water play with ocean animal toys, Toddler Time keeps even the busiest of bodies engaged and entertained. A myriad of developmentally age-appropriate, hands-on activities await for tots to explore."
        data["ages"] = "0 - 5"
        data["imageURL"] = ""
        data["imageObjectId"] = "MrXAwEQqHC"

        testData["1"] =  data
    }

    func saveTestData() {

        for entry in self.testData {
            if let test = self.testData[entry.key] {
                let eventObject: PFObject = PFObject(className: "EventObject")
                eventObject["title"] = test["title"]
                eventObject["allEventDates"] = test["allEventDates"] as! [Date];
                eventObject["startDate"] = test["startDate"] as! Date
                eventObject["endDate"] = test["endDate"] as! Date
                eventObject["allDay"] = test["allDay"] as! Bool
                eventObject["startTime"] = test["startTime"] as? String
                eventObject["endTime"] = test["endTime"] as? String
                eventObject["free"] = test ["free"] as! Bool
                eventObject["price"] =  test["price"] as! String
                eventObject["originalEventURL"] = test["originalEventURL"] as! String
                eventObject["location"] = test["location"] as! String
                eventObject["locationHours"] = test["locationHours"] as! String
                eventObject["address"] = test["address"] as! String
                eventObject["description"] = test["description"] as! String
                eventObject["ages"] = test["ages"] as! String
                eventObject["imageURL"] = test["imageURL"] as! String
                eventObject["imageObjectId"] = test["imageObjectId"] as! String

                let alleventdates = test["allEventDates"] as! [Date];

                //event object has all the date it needs. Save it now. In the completion handler
                //we can check which dates it needs to have relation with.
                guard let _ = try? eventObject.save() else { return }

                for date in alleventdates {
                    //let date = alleventdates[0]
                    let q = PFQuery(className: "EventDate")
                    q.whereKey("eventDate", equalTo: date)
                    if let eventDateObjects = try? q.findObjects() {
                        if eventDateObjects.count == 0 {
                            let dateObject: PFObject = PFObject(className: "EventDate")
                            dateObject["eventDate"] = date
                            let relation = dateObject.relation(forKey: "events")
                            relation.add(eventObject)
                            guard let _ = try? dateObject.save() else { return }
                        } else {
                            let existingDateObject = eventDateObjects[0]
                            let relation = existingDateObject.relation(forKey: "events")
                            relation.add(eventObject)
                            guard let _ = try? existingDateObject.save() else { return }
                        }
                    }
                }

            }
        }
        //  })

    }


    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.dates.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = dateListTable.make(withIdentifier: "dateCell", owner: nil) as? NSTableCellView {
            self.dateFormatter.dateFormat = "MM-dd-YYYY"
            print(dates[row])
            cell.textField?.stringValue =  self.dateFormatter.string(from: dates[row])
            return cell
        }
        return nil
    }


}

