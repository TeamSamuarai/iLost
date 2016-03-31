//
//  BeaconIist.swift
//  Footprint
//
//  Created by Terry Liao on 16/2/4.
//  Copyright © 2016年 TeamSamurai. All rights reserved.
//
/*
Abstract:
This is a subsitute to JSON data base with Hardcode Version for storing data
The testing purpose only
*/
import Foundation
struct beaconInfo {
    var Major:NSNumber
    var Minor:NSNumber
    var addrX:Double
    var addrY:Double
}

func make_list()->[beaconInfo]{
    
    var beaconList:[beaconInfo] = []
    beaconList.append(beaconInfo(Major: 101, Minor: 1, addrX: 100, addrY: 350))
    beaconList.append(beaconInfo(Major: 101, Minor: 2, addrX: 150, addrY: 320))
    beaconList.append(beaconInfo(Major: 101, Minor: 3, addrX: 200, addrY: 350))
    beaconList.append(beaconInfo(Major: 101, Minor: 4, addrX: 250, addrY: 320))
    beaconList.append(beaconInfo(Major: 101, Minor: 5, addrX: 300, addrY: 350))
    beaconList.append(beaconInfo(Major: 101, Minor: 6, addrX: 350, addrY: 320))
    beaconList.append(beaconInfo(Major: 101, Minor: 7, addrX: 400, addrY: 350))
    beaconList.append(beaconInfo(Major: 101, Minor: 8, addrX: 450, addrY: 320))
    beaconList.append(beaconInfo(Major: 101, Minor: 9, addrX: 500, addrY: 350))
    beaconList.append(beaconInfo(Major: 101, Minor: 10, addrX: 550, addrY: 320))
    beaconList.append(beaconInfo(Major: 101, Minor: 11, addrX: 600, addrY: 350))
    beaconList.append(beaconInfo(Major: 101, Minor: 12, addrX: 650, addrY: 320))
    
    return beaconList
    
}

func findRoom(roomNum:String)->(addrX:Double,addrY:Double){
    var addrX,addrY:Double
    switch roomNum{
    case "EG1101":
        addrX = 40
        addrY = 355
        break
    case "EG1102":
        addrX = 220
        addrY = 335
        break
    case "EG1103":
        addrX = 120
        addrY = 355
        break
    case "EG1105":
        addrX = 175
        addrY = 355
        break
    case "EG1106":
        addrX = 250
        addrY = 335
        break
    case "EG1107":
        addrX = 255
        addrY = 360
        break
    case "EG1111":
        addrX = 340
        addrY = 360
        break
    case "EG1114":
        addrX = 425
        addrY = 328
        break
    case "EG1115":
        addrX = 425
        addrY = 360
        break
    case "EG1116":
        addrX = 500
        addrY = 328
        break
    case "EG1119":
        addrX = 515
        addrY = 360
        break
        
        
        
    default:
        addrX = 0
        addrY = 0
        break
        
    }
    
    
    return(addrX,addrY)
}

func getRoomTable(selectMap:String, mapList:[String]) ->[String]{
    var roomTable = [String]()
   let Maps = ["EngrGwy_1F","EngrGwy_2F","EngrGwy_3F"]
    switch selectMap {
    case Maps[0]:
        roomTable = ["EG1101", "EG1102", "EG1103","EG1105","EG1106","EG1107","EG1111","EG1114","EG1115","EG1116","EG1119"]
        break
    case Maps[1]:
        roomTable = ["EG2101", "EG2102", "EG2105","EG2107","EG2110","EG2111","EG2115","EG2118","EG2119","EG2123","EG2124","EG2126","EG2127"]
        break
    case Maps[2]:
        roomTable = ["EG3100","EG3101","EG3102","EG3106","EG3107","EG3108","EG3111","EG3112","EG3115","EG3116","EG3121","EG3127"]
        break
    default:
        break
        
    }
    
    
    return roomTable
}

func mapList()->[String]{
    let Maps = ["EngrGwy_1F","EngrGwy_2F","EngrGwy_3F"]
    return Maps
    
}



