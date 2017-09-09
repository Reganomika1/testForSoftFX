//
//  DataViewController.swift
//  TestForSoftFX
//
//  Created by Macbook on 09.09.17.
//  Copyright © 2017 Macbook. All rights reserved.
//

import UIKit
import CoreData
import ReachabilitySwift
import Fuzi

class Item {
    var title = ""
    var date = ""
    var text = ""
}


class DataViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var entityDescript :NSEntityDescription!
    
    let reachability = Reachability()
    
    var fetchedControl: NSFetchedResultsController<NSFetchRequestResult>!
    
    var pageIndex: Int!
    
    var limit:Int = 4
    
    var isAllDataFetched:Bool = false
    var dataObject: String = ""
    var strXMLData:String = ""
    
    var items = [Item]();
    var item = Item();
    var foundCharacters = "";
    
    var parser = XMLParser()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 150
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.tableFooterView = UIView()
        
        entityDescript = NSEntityDescription.entity(forEntityName: "NewsItem", in: CoreDataManager.shared.managedObjectContext)
        
        fetchedControl = CoreDataManager.shared.getFetchedResultController(entityName: "NewsItem", sortDescriptor: "date", ascending: false)
        fetchedControl.delegate = self
        
        if pageIndex == 0{
            fetchedControl.fetchRequest.predicate = NSPredicate(format: "type == %@", "live")
        } else {
            fetchedControl.fetchRequest.predicate = NSPredicate(format: "type == %@", "analytics")
        }
        fetch()
    }
    
    func fetch(){
        fetchedControl.fetchRequest.fetchLimit = limit
        
        do {
            try fetchedControl.performFetch()
            
            if let count = fetchedControl.fetchedObjects?.count{
                if count < limit{
                    isAllDataFetched = true
                } else {
                    isAllDataFetched = false
                }
            }
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
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
        
        parser.parse()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let scrollViewHeight = scrollView.frame.size.height
        let scrollContentSizeHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        
        if (scrollOffset + scrollViewHeight == scrollContentSizeHeight){
            if reachability?.isReachable == false {
                if isAllDataFetched == false {
                    limit += 4
                    fetch()
                    tableView.reloadData()
                }
            }
        }
    }

}

//MARK: - UITableViewDataSource

extension DataViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fc = self.fetchedControl{
            if let objects = fc.fetchedObjects{
                return objects.count
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "idCell", for: indexPath) as! NewsItemTableViewCell
        
        let currentItem = fetchedControl.object(at: indexPath) as! NewsItem
        
        cell.titleLabel.text = currentItem.title
        cell.dateLabel.text = currentItem.date
        cell.newsDescription.text = currentItem.text
        
        return cell
    }
}

//MARK: - XMLParserDelegate

extension DataViewController: XMLParserDelegate{
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "title" {
            self.item.title = self.foundCharacters
        }
        
        if elementName == "pubDate" {
            self.item.date = self.foundCharacters
        }
        
        if elementName == "description"{
            self.item.text = self.foundCharacters
        }
        
        if elementName == "item" {
            let tempItem = Item()
            tempItem.title = self.item.title
            tempItem.date = self.item.date
            tempItem.text = self.item.text
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
    
    func parserDidEndDocument(_ parser: XMLParser) {
        
        
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
            
            do {
                let doc = try XMLDocument(string: element.text)

                if let root = doc.root {
                    item.text = root.stringValue
                }
            } catch let error {
                print(error)
            }
            
            if pageIndex == 0{
                item.type = "live"
            } else {
                item.type = "analytics"
            }
 
            CoreDataManager.shared.saveContext()
        }
        if items.count == 0{
            fetch()
        }
        
        tableView.reloadData()
    }
}

//MARK : - NSFetchedResultsControllerDelegate

extension DataViewController: NSFetchedResultsControllerDelegate{
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        if let userDefaults = UserDefaults(suiteName: "group.TodayExtensionDate"){
            
            let dateFormatter = DateFormatter()
            
            dateFormatter.dateFormat = "dd MMM yyyy hh:mm:ss"
            
            let dateString = dateFormatter.string(from: Date())
            
            userDefaults.set(dateString, forKey: "lastUpdate")
            
            userDefaults.synchronize()
        }
    }
}


