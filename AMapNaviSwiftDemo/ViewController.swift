//
//  ViewController.swift
//  AMapNaviSwiftDemo
//
//  Created by 刘博 on 16/4/12.
//  Copyright © 2016年 AutoNavi. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController,MAMapViewDelegate,AMapNaviManagerDelegate,AMapNaviViewControllerDelegate {

    //MARK: - Properties
    
    let startPoint = AMapNaviPoint.locationWithLatitude(39.989614, longitude: 116.481763)
    let endPoint = AMapNaviPoint.locationWithLatitude(39.983456, longitude: 116.315495)
    
    var calRouteSuccess = false
    var annotations = [MAAnnotation]()
    let naviManager = AMapNaviManager()
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var mapView: MAMapView!
    var polyline: MAPolyline?
    var naviViewController: AMapNaviViewController?
    
    //MARK: - Life Cycle
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setToolbarHidden(false, animated: false);
        
        naviManager.delegate = self
        
        initToolBar()
        
        configSubViews()
        
        configMapView()
        
        initAnnotations()
    }
    
    //MARK: - Initilization
    
    func initToolBar() {
        let flexbleItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let calcroute = UIBarButtonItem(title: "路径规划", style: .Plain, target: self, action:#selector(calculateRoute))
        let simunavi = UIBarButtonItem(title: "模拟导航", style: .Plain, target: self, action:#selector(startSimuNavi))
        
        setToolbarItems([flexbleItem,calcroute,flexbleItem,simunavi,flexbleItem], animated: false)
    }
    
    func configSubViews() {
        let startPointLabel = UILabel(frame: CGRectMake(0, 70, 320, 20))
        startPointLabel.textAlignment = .Center
        startPointLabel.font = UIFont.systemFontOfSize(14)
        startPointLabel.text = "起点: \(startPoint.latitude), \(startPoint.longitude)"
        
        view.addSubview(startPointLabel)
        
        let endPointLabel = UILabel(frame: CGRectMake(0, 100, 320, 20))
        endPointLabel.textAlignment = .Center
        endPointLabel.font = UIFont.systemFontOfSize(14)
        endPointLabel.text = "终点: \(endPoint.latitude), \(endPoint.longitude)"
        
        view.addSubview(endPointLabel)
    }
    
    func configMapView() {
        mapView = MAMapView(frame: CGRectMake(0, 130, CGRectGetWidth(view.bounds), CGRectGetHeight(view.bounds)-170))
        mapView.delegate = self
        
        view.insertSubview(mapView, atIndex: 0)
    }
    
    func initAnnotations(){
        let startAnn = MAPointAnnotation()
        startAnn.coordinate = CLLocationCoordinate2DMake(Double(startPoint.latitude), Double(startPoint.longitude))
        startAnn.title = "Start"
        
        annotations.append(startAnn)
        
        let endAnn = MAPointAnnotation()
        endAnn.coordinate = CLLocationCoordinate2DMake(Double(endPoint.latitude), Double(endPoint.longitude))
        endAnn.title = "End"
        
        annotations.append(endAnn)
        
        mapView.addAnnotations(annotations)
    }
    
    func initNaviViewController() {
        guard naviViewController == nil else { return }
        
        naviViewController = AMapNaviViewController(delegate: self)
    }
    
    //MARK: - Navi Control
    
    // 模拟导航
    func startSimuNavi()
    {
        if calRouteSuccess {
            initNaviViewController()
            
            naviManager.presentNaviViewController(naviViewController!, animated: false)
        }
        else {
            let alert = UIAlertView(title: "请先进行路线规划", message: nil, delegate: nil, cancelButtonTitle: "确定")
            alert.show()
        }
    }
    
    // 路径规划
    func calculateRoute() {
        // 驾车路径规划
        naviManager.calculateDriveRouteWithStartPoints([startPoint], endPoints: [endPoint], wayPoints: nil, drivingStrategy: .Default)
    }
    
    // 展示规划路径
    func showRouteWithNaviRoute(naviRoute: AMapNaviRoute)
    {
        guard let mapView = self.mapView else { return }
        
        mapView.removeOverlays(mapView.overlays)
        
        var coordinates = [CLLocationCoordinate2D]()
        for aCoordinate in naviRoute.routeCoordinates {
            coordinates.append(CLLocationCoordinate2DMake(Double(aCoordinate.latitude), Double(aCoordinate.longitude)))
        }
        
        polyline = MAPolyline(coordinates:&coordinates, count: UInt(naviRoute.routeCoordinates.count))
        
        mapView.addOverlay(polyline)
    }
    
    //MARK: - MAMapViewDelegate
    
    func mapView(mapView: MAMapView!, viewForOverlay overlay: MAOverlay!) -> MAOverlayView! {
        if overlay.isKindOfClass(MAPolyline) {
            let polylineView = MAPolylineView(overlay: overlay)
            
            polylineView.lineWidth = 5.0
            polylineView.strokeColor = UIColor.redColor()
            
            return polylineView
        }
        return nil
    }
    
    func mapView(mapView: MAMapView!, viewForAnnotation annotation: MAAnnotation!) -> MAAnnotationView! {
        if annotation.isKindOfClass(MAPointAnnotation) {
            let annotationIdentifier = "annotationIdentifier"
            
            var poiAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(annotationIdentifier) as? MAPinAnnotationView
            
            if poiAnnotationView == nil {
                poiAnnotationView = MAPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            }
            
            poiAnnotationView!.animatesDrop   = true
            poiAnnotationView!.canShowCallout = true
            
            return poiAnnotationView;
        }
        return nil
    }
    
    //MARK: - AMapNaviManagerDelegate
    
    // 算路成功回调
    func naviManagerOnCalculateRouteSuccess(naviManager: AMapNaviManager!) {
        NSLog("CalculateRouteSuccess")
        
        showRouteWithNaviRoute(naviManager.naviRoute);
        
        calRouteSuccess = true
    }
    
    // 展示导航视图回调
    func naviManager(naviManager: AMapNaviManager!, didPresentNaviViewController naviViewController: UIViewController!) {
        NSLog("didPresentNaviViewController")
        
        self.naviManager.startEmulatorNavi()
    }
    
    // 导航播报信息回调
    func naviManager(naviManager: AMapNaviManager!, playNaviSoundString soundString: String!, soundStringType: AMapNaviSoundType) {
        NSLog("%@", soundString)
        
        if speechSynthesizer.speaking {
            speechSynthesizer.stopSpeakingAtBoundary(.Word)
        }
        
        let aUtterance = AVSpeechUtterance(string: soundString)
        aUtterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        
        speechSynthesizer.speakUtterance(aUtterance)
    }
    
    //MARK: - AMapNaviViewControllerDelegate
    
    // 导航界面关闭按钮点击的回调
    func naviViewControllerCloseButtonClicked(naviViewController: AMapNaviViewController!) {
        speechSynthesizer.stopSpeakingAtBoundary(.Immediate)
        
        naviManager.stopNavi()
        naviManager.dismissNaviViewControllerAnimated(true)
    }
    
    // 导航界面更多按钮点击的回调
    func naviViewControllerMoreButtonClicked(naviViewController: AMapNaviViewController!) {
        if let showMode = self.naviViewController?.viewShowMode {
            switch showMode {
            case .CarNorthDirection:
                self.naviViewController!.viewShowMode = .MapNorthDirection
            case .MapNorthDirection:
                self.naviViewController!.viewShowMode = .CarNorthDirection
            }
        }
    }
    
    // 导航界面转向指示View点击的回调
    func naviViewControllerTurnIndicatorViewTapped(naviViewController: AMapNaviViewController!) {
        naviManager.readNaviInfoManual()
    }
    
}
