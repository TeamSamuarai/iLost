//
//  ViewController.swift
//  iLost_UI
//
//  Created by Xiao Chen on 2/4/16.
//	modified by Jinliang Liao on 2/15/16
//  Copyright (c) 2016 Team Samurai. All rights reserved.
//
/************************************************************
Abstract:
This class manages an table view for distination search, the room list
will be pass in and display in the table as cells. after one cell is selected
it will pass the cell deta as the room number to viewcontroller class.

**************************************************************/
import Foundation
import UIKit



class FirstTableViewController:UITableViewController{
	
	var FirstTableArray = [String]()
	
	var Map:String!
	
	//    var roomNum:String!
	
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
	
	
	
	//segue activity for view switching
	let blogSegueIdentifier = "roomNumber"
	
	// MARK: - Navigation
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == blogSegueIdentifier {
			if let destination = segue.destinationViewController as? ViewController {
				let indexPath = self.tableView.indexPathForSelectedRow
				destination.destinationRoom = FirstTableArray[(indexPath?.row)!]
				destination.Mapfilename = self.Map
				destination.showDesination()
				destination.timer.invalidate()
			}
		}
	}
	
	
	
	
	
	
}

