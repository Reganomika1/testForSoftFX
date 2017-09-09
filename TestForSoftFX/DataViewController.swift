//
//  DataViewController.swift
//  TestForSoftFX
//
//  Created by Macbook on 09.09.17.
//  Copyright © 2017 Macbook. All rights reserved.
//

import UIKit
import CoreData

class Item {
    var title = "";
    var date = "";
}


class DataViewController: UIViewController,NSFetchedResultsControllerDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var entityDescript :NSEntityDescription!
    
    var fetchedControl: NSFetchedResultsController<NSFetchRequestResult>!
    
    var pageIndex: Int!
    
    var dataObject: String = ""
    var strXMLData:String = ""
    
    var items = [Item]();
    var item = Item();
    var foundCharacters = "";
    
    var parser = XMLParser()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 70
        
        tableView.tableFooterView = UIView()
        
        entityDescript = NSEntityDescription.entity(forEntityName: "NewsItem", in: CoreDataManager.shared.managedObjectContext)
        
        fetchedControl = CoreDataManager.shared.getFetchedResultController(entityName: "NewsItem", sortDescriptor: "date", ascending: false)
        fetchedControl.delegate = self
        
        do {
            try fetchedControl.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        items.removeAll()
        
        titleLabel.text = dataObject
        switch pageIndex {
        case 0:
            parse(url:"https://widgets.spotfxbroker.com:8088/GetLiveNewsRss")
            break
        case 1:
            parse(url:"https://widgets.spotfxbroker.com:8088/GetAnalyticsRss")
            break
        default:
            break
        }
    }
    
    func parse(url: String){
        
        let url = NSURL(string: url)
        
        parser = XMLParser(contentsOf: url! as URL)!
        parser.delegate = self
        
        let success:Bool = parser.parse()
        
        if success {
            print("parse success!")
            
            print(strXMLData)
            
            
        } else {
            print("parse failure!")
        }
    }

}

//MARK: - UITableViewDataSource

extension DataViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "idCell", for: indexPath) as! NewsItemTableViewCell
        
        let currentItem = items[indexPath.row]
        
        cell.titleLabel.text = currentItem.title
        cell.dateLabel.text = currentItem.date
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

extension DataViewController: XMLParserDelegate{
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "title" {
            self.item.title = self.foundCharacters
        }
        
        if elementName == "pubDate" {
            self.item.date = self.foundCharacters
        }
        
        if elementName == "item" {
            let tempItem = Item()
            tempItem.title = self.item.title
            tempItem.date = self.item.date
            self.items.append(tempItem)
        }
        self.foundCharacters = ""
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {

        self.foundCharacters += string;
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("failure error: ", parseError)
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
        
        
        flag: for element in items {
            
            let fetchedItems = self.fetchedControl.fetchedObjects as! [NewsItem]
            for object in fetchedItems {
                if object.title == element.title {
                    continue flag
                }
            }
            
            let item = NewsItem(entity: self.entityDescript, insertInto: CoreDataManager.shared.managedObjectContext)
            item.title = element.title
            item.date = element.date
 
            CoreDataManager.shared.saveContext()
        }

        
        tableView.reloadData()
    }

}


//MARK: - UITableViewDataSource

extension DataViewController: UITableViewDelegate {
    

}


