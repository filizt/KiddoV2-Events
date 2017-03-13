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
    @IBOutlet weak var eventPriceField: NSTextField!
    @IBOutlet weak var eventEndTimePicker: NSDatePicker!
    @IBOutlet weak var eventStartTimePicker: NSDatePicker!

    var dates = [Date]() {
        didSet {
            dateListTable.reloadData()
        }
    }

    var dateFormatter = DateFormatter()



    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
                   }
    }

    var textFields = [NSTextField]()
    private var testData = [String: [String: Any]]()
    private var imageTestData = [String: [String: Any]]()
    var data = [String: Any]()
    
    //To-Do: Make this an Enum later
    let eventCategories = ["Pick One", "Story Time","Arts/Crafts/Music/Swim","Indoor Play", "Outdoor Play","Mommy and Me","Museums","Nature/Science","Out and About","Outdoor Activity","Parent's Date Night","Shows/Concerts/Theatre","Festival and Fairs","CoffeeShop","Brewery","Others",]

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

        //Can't save images!
        //createImageTestData()
        //uploadEventImagesFromLocalSource()

    }

    //For now we can just delete a date and can't update it.
    @IBAction func endEditingText(_ sender: NSTextField) {
        let row = dateListTable.row(for: sender)
        let column = dateListTable.column(for: sender)
        print("Row: ", row)
        if sender.stringValue.isEmpty {
            if dates.count > row {
                print("dates.count", dates.count)
                dates.remove(at: row)
            }
        }
        dateListTable.reloadData()

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
        guard saveToParse() else { return }

        //if everything above is true then show success pop-up
        performSegue(withIdentifier: "alertView", sender: nil)

    }


    private func setImageCacheLimit() {
        let cacheObject: PFObject = PFObject(className: "ImageCache")
        cacheObject["limit"] = 50

        guard let _ = try? cacheObject.save() else { return }
    }

    private func saveToParse() -> Bool {

        guard data.count > 0 else { return false }

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
        guard let _ = try? eventObject.save() else { return false }
        print("Event object saved")

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
                    guard let _ = try? dateObject.save() else { return false }
                    print("Date object created and event object linked to the date object")
                } else {
                    let existingDateObject = eventDateObjects[0]
                    let relation = existingDateObject.relation(forKey: "events")
                    relation.add(eventObject)
                    guard let _ = try? existingDateObject.save() else { return false }
                    print("Event object linked to existing date object")
                }
            }
        }

        return true
    }

    private func prepareData() -> Bool {
        data = [String: Any]()
        data["title"] = eventTitle.stringValue
        data["allEventDates"] = self.dates
        data["startDate"] = Date()
        data["endDate"] = Date()
        data["allDay"] = allDayCheckButton.state != 0 ? true : false
        self.dateFormatter.dateFormat = "h:mm a"
        data["startTime"] = eventStartTimePicker.isEnabled ? dateFormatter.string(from: eventStartTimePicker.dateValue) : ""
        data["endTime"] = eventEndTimePicker.isEnabled ? dateFormatter.string(from: eventEndTimePicker.dateValue) : ""
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
        //if let sender = freeEventCheckButton as! NSButton {
            switch sender.state {
            case NSOnState:
                eventPriceField.isEnabled = false
            case NSOffState:
                eventPriceField.isEnabled = true
            default:
                print("should not hit here")
            }
        //}
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

    private func createImageTestData() {
        var imageData = [String: Any]()
        imageData["category"] = "Aquarium"
        imageData["imageName"] = "aquarium"
        imageTestData["0"] = imageData

        imageData = [String: Any]()
        imageData["category"] = "Aquarium"
        imageData["imageName"] = "aquarium2"
        imageTestData["1"] = imageData

        imageData = [String: Any]()
        imageData["category"] = "Arts"
        imageData["imageName"] = "artsGeneric"
        imageTestData["2"] = imageData

        imageData = [String: Any]()
        imageData["category"] = "Brewery"
        imageData["imageName"] = "beerTap"
        imageTestData["3"] = imageData

        imageData = [String: Any]()
        imageData["category"] = "Shows"
        imageData["imageName"] = "classicalTheatre"
        imageTestData["4"] = imageData

        imageData = [String: Any]()
        imageData["category"] = "CoffeeShop"
        imageData["imageName"] = "coffeeShop"
        imageTestData["5"] = imageData

        imageData = [String: Any]()
        imageData["category"] = "Museums"
        imageData["imageName"] = "EMPlicensed"
        imageTestData["6"] = imageData

        imageData = [String: Any]()
        imageData["category"] = "fitnessForMom"
        imageData["imageName"] = "fitnessForMom"
        imageTestData["7"] = imageData

        imageData = [String: Any]()
        imageData["category"] = "girlColoring"
        imageData["imageName"] = "girlColoring"
        imageTestData["8"] = imageData

        imageData = [String: Any]()
        imageData["category"] = "grassNature"
        imageData["imageName"] = "grassNature"
        imageTestData["9"] = imageData


        imageData = [String: Any]()
        imageData["category"] = "Aquarium"
        imageData["imageName"] = "Aquarium2"
        imageTestData["9"] = imageData


        imageData = [String: Any]()
        imageData["category"] = "IndoorGym"
        imageData["imageName"] = "IndoorGym"
        imageTestData["10"] = imageData


        imageData = [String: Any]()
        imageData["category"] = "Arts"
        imageData["imageName"] = "ClassicalMusic"
        imageTestData["11"] = imageData

        imageData = [String: Any]()
        imageData["category"] = "kidsNature"
        imageData["imageName"] = "kidsNature"
        imageTestData["12"] = imageData


        imageData = [String: Any]()
        imageData["category"] = "kidSwimming"
        imageData["imageName"] = "kidSwimming"
        imageTestData["13"] = imageData


        imageData = [String: Any]()
        imageData["category"] = "libraryGeneric"
        imageData["imageName"] = "libraryGeneric"
        imageTestData["14"] = imageData


        imageData = [String: Any]()
        imageData["category"] = "Library"
        imageData["imageName"] = "LibraryGeneric"
        imageTestData["15"] = imageData


        imageData = [String: Any]()
        imageData["category"] = "MusicGeneric"
        imageData["imageName"] = "MusicGeneric"
        imageTestData["16"] = imageData

        imageData = [String: Any]()
        imageData["category"] = "outdoorPlayground"
        imageData["imageName"] = "outdoorPlayground"
        imageTestData["17"] = imageData

        imageData = [String: Any]()
        imageData["category"] = "outdoorSwing"
        imageData["imageName"] = "outdoorSwing"
        imageTestData["18"] = imageData

        imageData = [String: Any]()
        imageData["category"] = "museums"
        imageData["imageName"] = "pacificScienceCenter"
        imageTestData["19"] = imageData

        imageData = [String: Any]()
        imageData["category"] = "museums"
        imageData["imageName"] = "pacificScienceCenter"
        imageTestData["20"] = imageData
        imageData = [String: Any]()

        imageData["category"] = "Arts"
        imageData["imageName"] = "paintbrushes"
        imageTestData["21"] = imageData
        imageData = [String: Any]()

        imageData["category"] = "Arts"
        imageData["imageName"] = "paintingKid"
        imageTestData["22"] = imageData
        imageData = [String: Any]()

        imageData["category"] = "Zoo"
        imageData["imageName"] = "pettingZoo"
        imageTestData["23"] = imageData
        imageData = [String: Any]()

        imageData["category"] = "Zoo"
        imageData["imageName"] = "puppetShow"
        imageTestData["24"] = imageData
        imageData = [String: Any]()

        imageData["category"] = "Zoo"
        imageData["imageName"] = "Swimming"
        imageTestData["25"] = imageData
        imageData = [String: Any]()

        imageData["category"] = "Zoo"
        imageData["imageName"] = "Zoo"
        imageTestData["26"] = imageData
        imageData = [String: Any]()

        imageData["category"] = "Zoo"
        imageData["imageName"] = "zooFlamingo"
        imageTestData["27"] = imageData
        imageData = [String: Any]()

        imageData["category"] = "Zoo"
        imageData["imageName"] = "zooPeacock"
        imageTestData["28"] = imageData
        imageData = [String: Any]()



    }

    private func uploadEventImagesFromLocalSource() {

        print ("Start uploading")

        for entry in self.imageTestData {
            if let test = self.imageTestData[entry.key] {
                let eventImage = PFObject(className: "EventImage")
                eventImage["category"] = test["category"] as! String
                eventImage["imageName"] = test["imageName"] as! String

               // let asset = NSDataAsset(name: "Zoo.jpg")
               // var pfFile = PFFile(data: (asset?.data)!)

                let image = NSImage(named: eventImage["imageName"] as! String)
                let name  = eventImage["imageName"] as! String
                print("IMAGE NAMED:", name)
//                print(image?.representations.first?.description)
//                 let bits = image?.representations.first
//                    if let data = bits.representation(using: .JPEG, properties: [:]){
//                        var pfFile = PFFile(data: data)
//
//                }


                if let cgImage = image?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
                    if let jpegData = bitmapRep.representation(using: NSBitmapImageFileType.JPEG, properties: [:]) {
                        let pfFile = PFFile(data: jpegData, contentType: "image/jpeg")
                            eventImage["image"] = pfFile
                            if let imagePFFile = try? pfFile.save() {
                                //image saved. Now try save eventImage object
                                guard let _ = try? eventImage.save() else { return }
                                print("IMAGE SAVED***:", name)
                            } else {
                                print("IMAGE IS NOT SAVED!!!")
                            }

                    }
                }
            }
        }
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

