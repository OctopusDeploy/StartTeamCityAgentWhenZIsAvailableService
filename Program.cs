using System;
using Topshelf;
using System.ServiceProcess;
using System.Diagnostics;
using System.Threading;
using System.IO;
using Serilog;

namespace StartTeamCityAgentWhenZIsAvailableService
{
    public class Program
    {

        bool _cancel;

        static void Main(string[] args)
        {
            var logLocation = Path.Combine(Path.GetDirectoryName(typeof(Program).Assembly.Location), "StartTeamCityAgentWhenZIsAvailableService.log");

            Log.Logger = new LoggerConfiguration()
                        .MinimumLevel.Verbose()
                        .WriteTo.ColoredConsole()
                        .WriteTo.File(Path.Combine(Path.GetTempPath(), "StartTeamCityAgentWhenZIsAvailableService.log"))
                        .WriteTo.File(logLocation)
                        .CreateLogger();
            
            Log.Verbose("Main {Args}", args);

            HostFactory.Run(x =>
            {
                Log.Verbose("HostFactory.Run");
                x.Service<Program>(s =>
                {
                    Log.Verbose("Service Setup");
                    s.ConstructUsing(name => new Program());
                    s.WhenStarted((tc, hc) => tc.Start(hc));
                    s.WhenStopped(tc => tc.Stop());
                });

                x.SetDescription("By Octopus Deploy");
                x.SetDisplayName("TeamCity Start Build Agent When Z Is Available");
                x.SetServiceName("StartTeamCityAgentWhenZIsAvailableService");

                x.DependsOn("LanmanWorkstation");
                x.DependsOn("Server");
                x.DependsOn("EventLog");
            });
            Log.Verbose("End main", args);
        }

        private bool Start(HostControl hc)
        {
            Log.Information("Starting");
            Log.Information("Setting TCBuildAgent to manual start");
            Process.Start("sc", "config TCBuildAgent start=demand");
            var thread = new Thread(() => Check(hc));
            thread.IsBackground = true;
            thread.Start();
            return true;
        }

        private void Check(HostControl hc)
        {
            Log.Information("Checking for Z drive existance");
            var sw = new Stopwatch();
            while (sw.Elapsed < TimeSpan.FromMinutes(2) && !Directory.Exists(@"Z:\"))
            {
                if(_cancel)
                    return;

                Log.Verbose("Z Does not exist");
                Thread.Sleep(TimeSpan.FromSeconds(1));
            }
            if (Directory.Exists(@"Z:\"))
                Log.Information("Z Exists");

            RestartTcService();
            Log.Information("Done");
            hc.Stop();
        }

        private void RestartTcService()
        {
            var service = new ServiceController("TCBuildAgent");
            service.Refresh();
            if (service.Status == ServiceControllerStatus.Running)
            {
                Log.Information("TCBuildAgent is running, stopping");
                service.Stop();
            }

            Log.Information("Starting TCBuildAgent Service");
            while (service.Status != ServiceControllerStatus.Stopped)
            {
                if(_cancel)
                    return;

                Log.Information("Waiting, service is: " + service.Status);
                Thread.Sleep(100);
                service.Refresh();
            }
            service.Start();
        }

        private void Stop()
        {
            _cancel = true;
            Log.Information("Stopping");
        }
    }
}
