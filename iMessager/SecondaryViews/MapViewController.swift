//
//  MapViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/30.
//

import UIKit
import MapKit
import CoreLocation


class MapViewController: UIViewController {
    
    // MARK: - Vars
    var location: CLLocation?
    var mapView: MKMapView!

    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // configuration
        configureTitle()
        configurationMapView()
        configureLeftBarButton()
    }
    
    // MARK: - Configurations
    private func configurationMapView() {
        
        mapView = MKMapView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        mapView.showsUserLocation = true
        
        if location != nil {
            mapView.setCenter(location!.coordinate, animated: false)
            // アノテーション付与
            mapView.addAnnotation(MapAnnotation(title: nil, coordinate: location!.coordinate))
        }
        
        view.addSubview(mapView)
        
    }
    
    private func configureLeftBarButton() {
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(self.backButtonPressed))
    }
    
    private func configureTitle() {
        self.title = "位置情報"
    }
    
    
    // MARK: - Actions
    @objc func backButtonPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
}
