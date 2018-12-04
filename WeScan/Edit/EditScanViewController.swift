//
//  EditScanViewController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/12/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import AVFoundation

/// The `EditScanViewController` offers an interface for the user to edit the detected quadrilateral.
final class EditScanViewController: UIViewController {
    
    lazy private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.isOpaque = true
        imageView.image = image
        imageView.backgroundColor = .black
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy private var quadView: QuadrilateralView = {
        let quadView = QuadrilateralView()
        quadView.editable = true
        quadView.translatesAutoresizingMaskIntoConstraints = false
        return quadView
    }()
    
    lazy private var nextButton: UIBarButtonItem = {
        let title = NSLocalizedString("wescan.edit.button.next", tableName: nil, bundle: Bundle(for: EditScanViewController.self), value: "Next", comment: "A generic next button")
        let button = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(pushReviewController))
        button.tintColor = navigationController?.navigationBar.tintColor
        return button
    }()
    
    lazy var backButton: UIButton = {
        let imageBack = UIImage(named: "icon_back")
        let button: UIButton = UIButton(type: .custom)
        button.setImage(imageBack, for: .normal)
        button.sizeToFit()
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 0)
        button.addTarget(self, action: #selector(cancelImageScannerController(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy private var shutterButton: UIView = {
        let bottomBar = UIView()
        let screenHeight = self.view.frame.size.height
        let screenWidth = self.view.frame.size.width
        let sellect = UIButton(frame: CGRect(x: 0, y: -5, width: 80, height: 80))
        sellect.setTitle("Chụp lại", for: .normal)
        sellect.addTarget(self, action: #selector(cancelImageScannerController), for: .touchUpInside)
        bottomBar.addSubview(sellect)
        
        let choose = UIButton(frame: CGRect(x: screenWidth - 80 , y: -5, width: 80, height: 80))
        choose.setTitle("Chọn", for: .normal)
        choose.addTarget(self, action: #selector(selectImage), for: .touchUpInside)
        bottomBar.addSubview(choose)
        
        bottomBar.backgroundColor = UIColor.init(red: 109/255, green: 110/255, blue: 113/255, alpha: 1).withAlphaComponent(0.8)
        bottomBar.frame = CGRect(x: 0, y: screenHeight - 130 , width: self.view.frame.width, height: 80)
        return bottomBar
    }()
    
    
    /// The image the quadrilateral was detected on.
    private let image: UIImage
    
    /// The detected quadrilateral that can be edited by the user. Uses the image's coordinates.
    private var quad: Quadrilateral
    
    private var quadViewWidthConstraint = NSLayoutConstraint()
    private var quadViewHeightConstraint = NSLayoutConstraint()
    
    // MARK: - Life Cycle
    
    init(image: UIImage, quad: Quadrilateral?) {
        self.image = image
        self.quad = quad ?? EditScanViewController.defaultQuad(forImage: image)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("wescan.scanning.title", tableName: nil, bundle: Bundle(for: ScannerViewController.self), value: "Scanning", comment: "The title of the ScannerViewController")
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        setupViews()
        setupConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustQuadViewConstraints()
        displayQuad()
    }
    
    
    @objc private func cancelImageScannerController(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true);
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
        // Work around for an iOS 11.2 bug where UIBarButtonItems don't get back to their normal state after being pressed.
        navigationController?.navigationBar.tintAdjustmentMode = .normal
        navigationController?.navigationBar.tintAdjustmentMode = .automatic
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        view.addSubview(imageView)
        view.addSubview(quadView)
        view.addSubview(shutterButton)
        view.bringSubview(toFront: shutterButton)
        
    }
    
    @objc func selectImage() {
        pushReviewController()
    }
    
    func btnConnectTouched(sender:UIButton!)
    {
        print("button connect touched")
    }
    
    private func setupConstraints() {
        let imageViewConstraints = [
            imageView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0),
            imageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0),
            imageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
            imageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0)
        ]
        let quadViewConstraints = [
            quadView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0),
            quadView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0),
            quadView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
            quadView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0)
        ]
        
        var shutterButtonBottomConstraint: NSLayoutConstraint
        
        if #available(iOS 11.0, *) {
            shutterButtonBottomConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: shutterButton.bottomAnchor, constant: 15.0)
        } else {
            shutterButtonBottomConstraint = view.bottomAnchor.constraint(equalTo: shutterButton.bottomAnchor, constant: 15.0)
        }
        
        let shutterButtonConstraints = [
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButtonBottomConstraint,
            shutterButton.widthAnchor.constraint(equalToConstant: 60),
            shutterButton.heightAnchor.constraint(equalToConstant: 60)
        ]
        
        
        NSLayoutConstraint.activate(quadViewConstraints + imageViewConstraints + shutterButtonConstraints )
        
    }
    
    // MARK: - Actions
    
    @objc func pushReviewController() {
        guard let quad = quadView.quad,
            var ciImage = CIImage(image: image) else {
                if let imageScannerController = navigationController as? ImageScannerController {
                    let error = ImageScannerControllerError.ciImageCreation
                    imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFailWithError: error)
                }
                return
        }
        
        let scaledQuad = quad.scale(quadView.bounds.size, image.size)
        self.quad = scaledQuad
        
        if image.size.width < image.size.height {
            let orientationTransform = ciImage.orientationTransform(forExifOrientation: 6)
            ciImage = ciImage.transformed(by: orientationTransform)
        }
        
        var cartesianScaledQuad = scaledQuad.toCartesian(withHeight: image.size.height)
        cartesianScaledQuad.reorganize()
        
        let filteredImage = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
            "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
            "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
            "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
            ])
        
        var uiImage: UIImage!
        
        // Let's try to generate the CGImage from the CIImage before creating a UIImage.
        if let cgImage = CIContext(options: nil).createCGImage(filteredImage, from: filteredImage.extent) {
            uiImage = UIImage(cgImage: cgImage)
        } else {
            uiImage = UIImage(ciImage: filteredImage, scale: 1.0, orientation: .up)
        }
        
        let results = ImageScannerResults(originalImage: image, scannedImage: uiImage, detectedRectangle: scaledQuad)
        if let imageScannerController = navigationController as? ImageScannerController {
            imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFinishScanningWithResults: results)
        }
    }
    
    private func displayQuad() {
        let imageSize = image.size
        let imageFrame = CGRect(x: quadView.frame.origin.x, y: quadView.frame.origin.y, width: quadViewWidthConstraint.constant, height: quadViewHeightConstraint.constant)
        
        let scaleTransform = CGAffineTransform.scaleTransform(forSize: imageSize, aspectFillInSize: imageFrame.size)
        let transforms = [scaleTransform]
        let transformedQuad = quad.applyTransforms(transforms)
        
        quadView.drawQuadrilateral(quad: transformedQuad, animated: false)
    }
    
    /// The quadView should be lined up on top of the actual image displayed by the imageView.
    /// Since there is no way to know the size of that image before run time, we adjust the constraints to make sure that the quadView is on top of the displayed image.
    private func adjustQuadViewConstraints() {
        let frame = AVMakeRect(aspectRatio: image.size, insideRect: imageView.bounds)
        quadViewWidthConstraint.constant = frame.size.width
        quadViewHeightConstraint.constant = frame.size.height
    }
    
    /// Generates a `Quadrilateral` object that's centered and one third of the size of the passed in image.
    private static func defaultQuad(forImage image: UIImage) -> Quadrilateral {
        let topLeft = CGPoint(x: image.size.width / 3.0, y: image.size.height / 3.0)
        let topRight = CGPoint(x: 2.0 * image.size.width / 3.0, y: image.size.height / 3.0)
        let bottomRight = CGPoint(x: 2.0 * image.size.width / 3.0, y: 2.0 * image.size.height / 3.0)
        let bottomLeft = CGPoint(x: image.size.width / 3.0, y: 2.0 * image.size.height / 3.0)
        
        let quad = Quadrilateral(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft)
        
        return quad
    }
    
}
