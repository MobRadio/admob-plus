@objc(AMSPlugin)
class AMSPlugin: CDVPlugin {
    static let testApplicationID = "ca-app-pub-3940256099942544~1458002511"
    var banner: AMSBanner!
    var readyCallbackId: String!
    
    var view: UIView {
        return self.viewController.view
    }
    override func pluginInitialize() {
        super.pluginInitialize()

        AMSAdBase.plugin = self
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    deinit {
        readyCallbackId = nil
    }

    func getApplicationID() -> String {
        let applicationID = commandDelegate.settings["APP_ID_IOS".lowercased()] as? String
        if applicationID == nil || applicationID == "" || applicationID == "test" {
            NSLog("admob is using testApplicationID")
            return AMSPlugin.testApplicationID
        }
        return applicationID!
    }

    @objc(ready:)
    func ready(command: CDVInvokedUrlCommand) {
        readyCallbackId = command.callbackId

        self.emit(eventType: AMSEvents.ready, data: [
            "platform": "ios",
            "applicationID": getApplicationID(),
            "sdkVersion": GADRequest.sdkVersion(),
            "isRunningInTestLab": false])
    }

    @objc(set_app_muted:)
    func set_app_muted(command: CDVInvokedUrlCommand) {
        guard let applicationMuted = command.argument(at: 0) as? Bool
            else {
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: false)
                self.commandDelegate!.send(result, callbackId: command.callbackId)
                return
        }
        GADMobileAds.sharedInstance().applicationMuted = applicationMuted

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        self.commandDelegate!.send(result, callbackId: command.callbackId)
    }

    @objc(set_app_volume:)
    func set_app_volume(command: CDVInvokedUrlCommand) {
        guard let applicationVolume = command.argument(at: 0) as? Float
            else {
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: false)
                self.commandDelegate!.send(result, callbackId: command.callbackId)
                return
        }
        GADMobileAds.sharedInstance().applicationVolume = applicationVolume

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        self.commandDelegate!.send(result, callbackId: command.callbackId)
    }

    @objc(banner_show:)
    func banner_show(command: CDVInvokedUrlCommand) {
        guard let opts = command.argument(at: 0) as? NSDictionary,
            let id = opts.value(forKey: "id") as? Int,
            let adUnitID = opts.value(forKey: "adUnitID") as? String,
            let position = opts.value(forKey: "position") as? String,
            let aux = AMSAdBase.ads[id] as? AMSBanner?
            else {
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: false)
                self.commandDelegate!.send(result, callbackId: command.callbackId)
                return
        }
        
        if aux == nil {
            let adSize = getAdSize(opts)
            self.banner = AMSBanner(id: id, adUnitID: adUnitID, adSize: adSize, position: position)
        }
        self.banner.show(request: createGADRequest(opts))

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        self.commandDelegate!.send(result, callbackId: command.callbackId)
    }

    @objc(banner_hide:)
    func banner_hide(command: CDVInvokedUrlCommand) {
        self.banner.hide()
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        self.commandDelegate!.send(result, callbackId: command.callbackId)
    }

    @objc(interstitial_is_loaded:)
    func interstitial_is_loaded(command: CDVInvokedUrlCommand) {
        guard let opts = command.argument(at: 0) as? NSDictionary,
            let id = opts.value(forKey: "id") as? Int,
            let interstitial = AMSAdBase.ads[id] as? AMSInterstitial
            else {
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: false)
                self.commandDelegate!.send(result, callbackId: command.callbackId)
                return
        }
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: interstitial.isLoaded())
        self.commandDelegate!.send(result, callbackId: command.callbackId)
    }

    @objc(interstitial_load:)
    func interstitial_load(command: CDVInvokedUrlCommand) {
        guard let opts = command.argument(at: 0) as? NSDictionary,
            let id = opts.value(forKey: "id") as? Int,
            let adUnitID = opts.value(forKey: "adUnitID") as? String,
            var interstitial = AMSAdBase.ads[id] as? AMSInterstitial?
            else {
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: false)
                self.commandDelegate!.send(result, callbackId: command.callbackId)
                return
        }
        if interstitial == nil {
            interstitial = AMSInterstitial(id: id, adUnitID: adUnitID)
        }
        interstitial!.load(request: createGADRequest(opts))

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        self.commandDelegate!.send(result, callbackId: command.callbackId)
    }

    @objc(interstitial_show:)
    func interstitial_show(command: CDVInvokedUrlCommand) {
        guard let opts = command.argument(at: 0) as? NSDictionary,
            let id = opts.value(forKey: "id") as? Int,
            let interstitial = AMSAdBase.ads[id] as? AMSInterstitial
            else {
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: false)
                self.commandDelegate!.send(result, callbackId: command.callbackId)
                return
        }
        interstitial.show()

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        self.commandDelegate!.send(result, callbackId: command.callbackId)
    }

    @objc(reward_video_is_ready:)
    func reward_video_is_ready(command: CDVInvokedUrlCommand) {
        guard let opts = command.argument(at: 0) as? NSDictionary,
            let id = opts.value(forKey: "id") as? Int,
            let rewardVideo = AMSAdBase.ads[id] as? AMSRewardVideo
            else {
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: false)
                self.commandDelegate!.send(result, callbackId: command.callbackId)
                return
        }
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: rewardVideo.isReady())
        self.commandDelegate!.send(result, callbackId: command.callbackId)
    }

    @objc(reward_video_load:)
    func reward_video_load(command: CDVInvokedUrlCommand) {
        guard let opts = command.argument(at: 0) as? NSDictionary,
            let id = opts.value(forKey: "id") as? Int,
            let adUnitID = opts.value(forKey: "adUnitID") as? String,
            var rewardVideo = AMSAdBase.ads[id] as? AMSRewardVideo?
            else {
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: false)
                self.commandDelegate!.send(result, callbackId: command.callbackId)
                return
        }
        if rewardVideo == nil {
            rewardVideo = AMSRewardVideo(id: id, adUnitID: adUnitID)
        }
        rewardVideo!.load(request: createGADRequest(opts))

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        self.commandDelegate!.send(result, callbackId: command.callbackId)
    }

    @objc(reward_video_show:)
    func reward_video_show(command: CDVInvokedUrlCommand) {
        guard let opts = command.argument(at: 0) as? NSDictionary,
            let id = opts.value(forKey: "id") as? Int,
            let rewardVideo = AMSAdBase.ads[id] as? AMSRewardVideo
            else {
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: false)
                self.commandDelegate!.send(result, callbackId: command.callbackId)
                return
        }
        rewardVideo.show()

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        self.commandDelegate!.send(result, callbackId: command.callbackId)
    }

    func createGADRequest(_ opts: NSDictionary) -> GADRequest {
        let request = GADRequest()
        if let testDevices = opts["testDevices"] as? [String] {
            request.testDevices = testDevices
        }
        if let childDirected = opts["childDirected"] as? Bool {
            GADMobileAds.sharedInstance().requestConfiguration.tag(forChildDirectedTreatment: childDirected)
        }
        return request
    }

    func emit(eventType: String, data: Any = false) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["type": eventType, "data": data])
        result?.setKeepCallbackAs(true)
        self.commandDelegate!.send(result, callbackId: readyCallbackId)
    }

    func getAdSize(_ opts: NSDictionary) -> GADAdSize {
       let frame = { () -> CGRect in
           // Here safe area is taken into account, hence the view frame is used
           // after the view has been laid out.
           if #available(iOS 11.0, *) {
               return view.frame.inset(by: view.safeAreaInsets)
           } else {
               return view.frame
           }
       }()
       let viewWidth = frame.size.width
        return GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
    }
}
