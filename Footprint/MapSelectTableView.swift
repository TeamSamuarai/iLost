//
//  MapSelectTableView.swift
//  Footprint
//
//  Created by Terry Liao on 16/3/3.
//  Copyright © 2016 Apple Inc. All rights reserved.
//

/************************************************************
Abstract:
This class manages an table view for map switching, the map list
will be pass in and display in the table as cells. after one cell is selected
it will pass the cell deta as the room number to viewcontroller class.

**************************************************************/

import Foundation
import UIKit

class MapSelectViewController:UITableViewController{
    
    var FirstTableArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FirstTableArray.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        let Cell = self.tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) //as! UITableViewCell
        Cell.textLabel?.text = FirstTableArray[indexPath.row]
        return Cell
        
    }
    
    
    let blogSegueIdentifier = "MapSelect"
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == blogSegueIdentifier {
            if let destination = segue.destinationViewController as? ViewController {
                let indexPath = self.tableView.indexPathForSelectedRow
                destination.Mapfilename = FirstTableArray[(indexPath?.row)!]
            }
        }
    }
    
    
}
