//
//  ViewController.swift
//  Kiddo Events
//
//  Created by Filiz Kurban on 3/1/17.
//  Copyright © 2017 Filiz Kurban. All rights reserved.
//

import Cocoa
import Parse

//enum Catagories: Int {
//    case ArtsCraftsMusicSwim = 1, IndoorPlay, OutdoorPlay,"Mommy and Me","Museums","Nature/Science","Out and About","Outdoor Activity","Parent's Date Night","Shows/Concerts/Theatre","Festival and Fairs","CoffeeShop","Brewery","Others"
//}

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var eventTitle: NSTextField!
    @IBOutlet weak var location: NSTextField!
    @IBOutlet weak var addDateButton: NSButton!
    @IBOutlet weak var datePicker: NSDatePicker!
    @IBOutlet weak var dateListTable: NSTableView!
    @IBOutlet weak var doneButton: NSButton!
    @IBOutlet weak var locationHours: NSTextField!

    @IBOutlet weak var eventImageObjectId: NSTextField!
    @IBOutlet weak var popularEventCheckButton: NSButton!
    @IBOutlet weak var eventActiveCheckButton: NSButton!
    @IBOutlet weak var freeEventCheckButton: NSButton!
    @IBOutlet weak var allDayCheckButton: NSButton!
    @IBOutlet weak var eventDescription: NSTextField!
    @IBOutlet weak var categoryList: NSPopUpButton!
    @IBOutlet weak var eventAges: NSTextField!
    @IBOutlet weak var eventURL: NSTextField!
    @IBOutlet weak var locationAddress: NSTextField!

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

    var textFields = [NSTextField]()

    var data = [String: Any]()
    //To-Do: Make this an Enum later
    let eventCategories = ["Pick One", "Arts/Crafts/Music/Swim","Indoor Play", "Outdoor Play","Mommy and Me","Museums","Nature/Science","Out and About","Outdoor Activity","Parent's Date Night","Shows/Concerts/Theatre","Festival and Fairs","CoffeeShop","Brewery","Others",]

    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.dateValue = Date()
        dateListTable.delegate = self
        dateListTable.dataSource = self

        textFields.append(eventTitle)
        textFields.append(location)
        textFields.append(locationHours)
        textFields.append(locationAddress)
        textFields.append(eventPriceField)
        textFields.append(eventAges)
        textFields.append(eventImageObjectId)

        categoryList.removeAllItems()
        categoryList.addItems(withTitles: eventCategories)


    }


    @IBAction func eventCategoryPicked(_ sender: NSPopUpButton) {
        print("Pop-up category item chosen:", sender.indexOfSelectedItem)
    }

    func addDate(_ sender: Any) {
        let date = datePicker.dateValue
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.day, .year, .month], from: date)
        let dateWithSetComponents = calendar.date(from: components)!
        dates.append(dateWithSetComponents)
    }

    @IBAction func doneButtonClicked(_ sender: Any) {
        guard validateFields() else { return }
        guard prepareData() else { return }

        saveToParse()

    }

    private func saveToParse() {

        guard data.count > 0 else { return }

        let eventObject: PFObject = PFObject(className: "EventObject")
        eventObject["title"] = data["title"]
        eventObject["allEventDates"] = data["allEventDates"] as! [Date];
        eventObject["startDate"] = data["startDate"] as! Date
        eventObject["endDate"] = data["endDate"] as! Date
        eventObject["allDay"] = data["allDay"] as! Bool
        eventObject["startTime"] = data["startTime"] as? String
        eventObject["endTime"] = data["endTime"] as? String
        eventObject["free"] = data ["free"] as! Bool
        eventObject["price"] =  data["price"] as! String
        eventObject["originalEventURL"] = data["originalEventURL"] as! String
        eventObject["location"] = data["location"] as! String
        eventObject["locationHours"] = data["locationHours"] as! String
        eventObject["address"] = data["address"] as! String
        eventObject["description"] = data["description"] as! String
        eventObject["ages"] = data["ages"] as! String
        eventObject["imageURL"] = data["imageURL"] as! String
        eventObject["isActive"] = data["isActive"] as! Bool
        eventObject["isPopular"] = data["isPopular"] as! Bool
        eventObject["imageObjectId"] = data["imageObjectId"] as! String
        eventObject["category"] = data["category"] as! String

        let alleventdates = data["allEventDates"] as! [Date];

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

    private func prepareData() -> Bool {
        data = [String: Any]()
        data["title"] = eventTitle.stringValue
        data["allEventDates"] = self.dates
        data["startDate"] = Date()
        data["endDate"] = Date()
        data["allDay"] = allDayCheckButton.state != 0 ? true : false
        self.dateFormatter.dateFormat = "h:mm a"
        data["startTime"] = dateFormatter.string(from: eventStartTimePicker.dateValue)
        data["endTime"] = dateFormatter.string(from: eventEndTimePicker.dateValue)
        data["free"] = freeEventCheckButton.state != 0 ? true : false
        data["price"] = eventPriceField.stringValue
        data["originalEventURL"] = eventURL.stringValue
        data["location"] = location.stringValue
        data["locationHours"] = locationHours.stringValue
        data["address"] = locationAddress.stringValue
        data["description"] = eventDescription.stringValue
        data["ages"] = eventAges.stringValue
        data["imageURL"] = ""
        data["isActive"] = eventActiveCheckButton.state != 0 ? true : false
        data["isPopular"] = popularEventCheckButton.state != 0 ? true : false
        data["imageObjectId"] = eventImageObjectId.stringValue
        data["category"] = eventCategories[categoryList.indexOfSelectedItem]

        return true
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
        var validationResult = true
        //check textFields
        for field in textFields {
            if field.stringValue.isEmpty {
                //exclude event price field, if event is free
                if field == eventPriceField && freeEventCheckButton.state == 1 {
                    field.backgroundColor = NSColor.white
                    continue
                }

                validationResult = false
                //field.layer?.borderColor = NSColor.red.cgColor
                field.backgroundColor = NSColor.red
            } else {
                field.backgroundColor = NSColor.white
            }
        }

        //check eventDescription
        if eventDescription.stringValue.isEmpty {
            eventDescription.backgroundColor = NSColor.red
            validationResult = false
        } else {
            eventDescription.backgroundColor = NSColor.white

        }

        //check if table has at least one entry
        if dates.count == 0 {
            dateListTable.backgroundColor = NSColor.red
            validationResult = false
        } else {
            dateListTable.backgroundColor = NSColor.white
        }

        //check if there is event start,end time if alldayevent flag is off.
//        if allDayCheckButton.state == 0 {
//            print ("checked")
//        } else {
//
//            if eventStartTimePicker.dateValue.timeIntervalSinceReferenceDate * -1 > 1000  {
//                print ("today")
//            } else {
//                print("Time: ", (eventStartTimePicker.dateValue.timeIntervalSinceReferenceDate * 1 ))
//            }
//        }

        //check if event price is entered, if freeEvent flag is off

        //for now category field can be empty
        if categoryList.indexOfSelectedItem == 0 {
             validationResult = false
        }

        return validationResult
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

