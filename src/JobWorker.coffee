AbstractJobManager = require './AbstractJobManager'

UppercaseProcessor = require './processors/UppercaseProcessor'
ImageMagickProcessor = require './processors/ImageMagickProcessor'
JobFlowManager = require './JobFlowManager'
MetadataImageProcessor = require './processors/MetadataImageProcessor'
ZipProcessor = require './processors/ZipProcessor'
VideoProcessor = require './processors/VideoProcessor'
async = require 'async'
_ = require("underscore")._
require './domain/Job'
JobContext = require "./domain/JobContext"
fs = require 'fs'

class JobWorker extends AbstractJobManager
  
  constructor:(@options)->
    super(@options)
    #@processor = new ImageMagickProcessor()
    #@processor = new UppercaseProcessor()
    #@processor = new VideoProcessor()
    @processClass = UppercaseProcessor
    @jobFlowManager = new JobFlowManager()
    
  takeJob:(err)=>
    self = @
    #if err then console.log err
    
    @jobFlowManager.processNext (err, job) ->
      if err then console.log err
      if job?  
        try 
          processorClass = require "./processors/new/#{job.processor}Processor"          
        catch e
          console.log e.stack
        
        missingProcessor = ()->
          return self.jobFlowManager.jobErrored({retry:false,errorMessage:"could not find processor:#{job.processor}Processor"}, job, self.takeJob)
        
        unless processorClass?
          missingProcessor()
          
        JobContext.create job, (err, jobContext)->
          if err then console.log err
          
          processor = new processorClass(jobContext)
          
          unless processor?
            missingProcessor()
            
          successful = ->
            fs.readdir jobContext.getCurrentFolder(), (err, files)->
              files = files || []
              job.outputFiles = _.map files, (f) -> jobContext.getCurrentFolder() + f
              relativeFilePaths = _.map files, (f) -> jobContext.getRelativeCurrentFolder() + f
              jobContext.mediaItem.setGenerateOutputFiles job.jobPath, relativeFilePaths, (err)->
                console.log err if err
                self.jobFlowManager.jobSuccessful job, self.takeJob
          try 
            processor.process(
              job
              (errorOptions) -> self.jobFlowManager.jobErrored(errorOptions, job, self.takeJob)
              () -> setTimeout(successful,10)

            )
          catch e
            missingProcessor()
            console.log e.stack
          
             
      else
        #console.log "job queue empty"
        setTimeout self.takeJob, 10
  


module.exports = JobWorker

