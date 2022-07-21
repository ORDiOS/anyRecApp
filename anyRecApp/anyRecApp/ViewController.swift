//
//  ViewController.swift
//  anyRecApp
//
//  Created by Oleksandr Revebtsov on 2022-07-19.
//

import UIKit
import AVFoundation
class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    
    // MARK: - Property for records
    
    @IBOutlet weak var recordButton: UIButton!
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var soundPlayer : AVAudioPlayer!
    var fileName: String = "audioFile.m4a"
    var observer : NSObjectProtocol!
    var isRecordingF = false

    override func viewDidLoad() {
        
        settingAudioSetting()
        
        self.observer = NotificationCenter.default.addObserver(forName:
              AVAudioSession.interruptionNotification, object: nil, queue: nil) {
                  [weak self] n in
            print("Handle Intrerupt...")
            if self!.isRecordingF {
                self!.audioRecorder.pause()
            }
                  guard let self = self else { return } // legal in Swift 4.2
                  let why = n.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt
                  let type = AVAudioSession.InterruptionType(rawValue: why)!
                  switch type {
                  case .began:
                      print("interruption began:\n\(n.userInfo!)")
                  case .ended:
                      if self.isRecordingF {
                          self.audioRecorder.record()
                          
                      }
                      print("interruption ended:\n\(n.userInfo!)")
                      guard let opt = n.userInfo![AVAudioSessionInterruptionOptionKey] as? UInt, !self.isRecordingF else {return}
                      let opts = AVAudioSession.InterruptionOptions(rawValue: opt)
                      if opts.contains(.shouldResume) {
                          print("should resume")
                          self.soundPlayer.prepareToPlay()
                          let ok = self.soundPlayer.play()
                          print("bp tried to resume play: did I? \(ok as Any)")
                      } else {
                          print("not should resume")
                      }
                  @unknown default:
                      fatalError()
                  }
          }
    }

    func startRecording() {
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            print("can't")
        }
        recordButton.backgroundColor = .green
        let audioFilename = getDocumentsDirectory().appendingPathComponent(fileName)

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            recordButton.setTitle("Tap to Stop", for: .normal)
            isRecordingF = true
        } catch {
            finishRecording(success: false)
        }
    }
    
    private func settingAudioSetting() {
        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordingUI()
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
    }
    
    private func loadRecordingUI() {
        recordButton.isHidden = false
    }
    
   
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func finishRecording(success: Bool) {
        print("-: Finished recording!")
        recordButton.backgroundColor = .red
        audioRecorder.stop()
        audioRecorder = nil

        if success {
            recordButton.setTitle("", for: .normal)
        } else {
            recordButton.setTitle("Tap to Record", for: .normal)
            // recording failed :(
        }
    }
    
    func setupPlayer() {
            let audioFilename = getDocumentsDirectory().appendingPathComponent(fileName)
            do {
                soundPlayer = try AVAudioPlayer(contentsOf: audioFilename)
                soundPlayer.delegate = self
                soundPlayer.prepareToPlay()
                soundPlayer.volume = 1.0
            } catch {
                print(error)
            }
        }
    
    @IBAction func recordTapped(_ sender: UIButton) {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
        
    }
    
    @IBAction func playRec(_ sender: UIButton) {
        do {
            try recordingSession.setCategory(.playback, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            print("can't")
        }
                   setupPlayer()
                   soundPlayer.play()
    }
    
  
    @objc func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    @IBAction func stopPlayRec(_ sender: Any) {
        soundPlayer.stop()
    }
    
    @IBAction func pauseRecording(_ sender: Any) {
        soundPlayer.pause()
    }
    
}

