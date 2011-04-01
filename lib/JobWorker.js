(function() {
  var AbstractJobManager, DataPrinter, JobWorker, UppercaseProcessor, jobWorker;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  AbstractJobManager = require('./AbstractJobManager');
  UppercaseProcessor = require('./processors/UppercaseProcessor');
  DataPrinter = require('./processors/DataPrinter');
  require('./domain/Job');
  JobWorker = (function() {
    __extends(JobWorker, AbstractJobManager);
    function JobWorker(options) {
      this.options = options;
      this.takeJob = __bind(this.takeJob, this);;
      JobWorker.__super__.constructor.call(this, this.options);
      this.processor = new DataPrinter();
    }
    JobWorker.prototype.takeJob = function() {
      var self;
      self = this;
      return Job.processNext(function(err, job) {
        if (job != null) {
          return self.processor.process(job, self.createErrorCallback(job), self.createCompletedCallback(job));
        } else {
          console.log("job queue empty");
          return setTimeout(self.takeJob, 1000);
        }
      });
    };
    JobWorker.prototype.createErrorCallback = function(job) {
      var self;
      self = this;
      return function(errorOptions) {
        var errorMethod;
        errorMethod = (errorOptions != null ? errorOptions.retry : void 0) === false ? "fail" : "retry";
        return job[errorMethod](function() {
          console.log("job: " + job._id + " errored, status:" + job.status + ", retryCount:" + job.retryCount);
          return self.takeJob();
        });
      };
    };
    JobWorker.prototype.createCompletedCallback = function(job) {
      var self;
      self = this;
      return function() {
        console.log("job: " + job._id + " completed");
        return job.complete(self.takeJob);
      };
    };
    return JobWorker;
  })();
  jobWorker = new JobWorker({
    mongoURL: "mongodb://localhost/media_engine"
  });
  jobWorker.takeJob();
}).call(this);