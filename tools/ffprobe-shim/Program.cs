using System;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Text.RegularExpressions;

internal static class Program
{
    private const string Ffmpeg = @"C:\kaifa_senlin\shipin-ai\tools\facefusion\bin\ffmpeg.exe";

    private static int Main(string[] args)
    {
        if (Array.Exists(args, item => item == "-version" || item == "--version"))
        {
            Console.WriteLine("ffprobe version hyperframes-shim-1.0");
            return 0;
        }

        var input = FindInput(args);
        if (string.IsNullOrWhiteSpace(input) || !File.Exists(input))
        {
            Console.Error.WriteLine("ffprobe shim: input media file was not found");
            return 1;
        }

        try
        {
            var metadata = ReadWithFfmpeg(input);
            Console.WriteLine(BuildJson(metadata, args));
            return 0;
        }
        catch (Exception error)
        {
            Console.Error.WriteLine("ffprobe shim: " + error.Message);
            return 1;
        }
    }

    private static string FindInput(string[] args)
    {
        for (var index = 0; index < args.Length - 1; index++)
        {
            if (args[index] == "--") return args[index + 1];
        }

        for (var index = args.Length - 1; index >= 0; index--)
        {
            if (!args[index].StartsWith("-", StringComparison.Ordinal)) return args[index];
        }

        return string.Empty;
    }

    private static MediaMetadata ReadWithFfmpeg(string input)
    {
        var start = new ProcessStartInfo
        {
            FileName = Ffmpeg,
            Arguments = "-hide_banner -i " + Quote(input),
            UseShellExecute = false,
            RedirectStandardError = true,
            RedirectStandardOutput = true,
            CreateNoWindow = true
        };

        using (var process = Process.Start(start))
        {
            var output = process.StandardError.ReadToEnd();
            process.WaitForExit();
            if (string.IsNullOrWhiteSpace(output)) throw new InvalidOperationException("FFmpeg returned no media metadata");
            return MediaMetadata.Parse(output);
        }
    }

    private static string BuildJson(MediaMetadata metadata, string[] args)
    {
        var selectAudio = Array.Exists(args, item => item == "a:0");
        var selectVideo = Array.Exists(args, item => item == "v:0");
        var duration = metadata.Duration.ToString("0.000000", CultureInfo.InvariantCulture);
        var streams = "";

        if (metadata.HasVideo && !selectAudio)
        {
            var frames = Math.Max(1, (int)Math.Round(metadata.Duration * metadata.Fps));
            streams += "{\"index\":0,\"codec_type\":\"video\",\"codec_name\":\"" + Escape(metadata.VideoCodec) + "\",\"codec_tag_string\":\"avc1\",\"width\":" + metadata.Width + ",\"height\":" + metadata.Height + ",\"r_frame_rate\":\"" + metadata.Fps.ToString("0.###", CultureInfo.InvariantCulture) + "/1\",\"avg_frame_rate\":\"" + metadata.Fps.ToString("0.###", CultureInfo.InvariantCulture) + "/1\",\"duration\":\"" + duration + "\",\"nb_frames\":\"" + frames + "\",\"nb_read_packets\":\"" + frames + "\",\"pix_fmt\":\"" + Escape(metadata.PixelFormat) + "\",\"color_space\":\"" + metadata.ColorSpace + "\",\"color_transfer\":\"" + metadata.ColorSpace + "\",\"color_primaries\":\"" + metadata.ColorSpace + "\"}";
        }

        if (metadata.HasAudio && !selectVideo)
        {
            if (streams.Length > 0) streams += ",";
            streams += "{\"index\":1,\"codec_type\":\"audio\",\"codec_name\":\"" + Escape(metadata.AudioCodec) + "\",\"sample_rate\":\"" + metadata.SampleRate + "\",\"channels\":" + metadata.Channels + ",\"duration\":\"" + duration + "\"}";
        }

        return "{\"streams\":[" + streams + "],\"format\":{\"duration\":\"" + duration + "\",\"format_name\":\"" + Escape(metadata.FormatName) + "\"}}";
    }

    private static string Quote(string value)
    {
        return "\"" + value.Replace("\"", "\\\"") + "\"";
    }

    private static string Escape(string value)
    {
        return (value ?? string.Empty).Replace("\\", "\\\\").Replace("\"", "\\\"");
    }

    private sealed class MediaMetadata
    {
        public double Duration;
        public bool HasVideo;
        public bool HasAudio;
        public string VideoCodec = "unknown";
        public string AudioCodec = "unknown";
        public int Width;
        public int Height;
        public double Fps = 30;
        public int SampleRate = 48000;
        public int Channels = 2;
        public string PixelFormat = "yuv420p";
        public string ColorSpace = "unknown";
        public string FormatName = "unknown";

        public static MediaMetadata Parse(string text)
        {
            var metadata = new MediaMetadata();
            var duration = Regex.Match(text, @"Duration:\s*(\d{2}):(\d{2}):(\d{2}(?:\.\d+)?)");
            if (duration.Success)
            {
                metadata.Duration = int.Parse(duration.Groups[1].Value) * 3600 + int.Parse(duration.Groups[2].Value) * 60 + double.Parse(duration.Groups[3].Value, CultureInfo.InvariantCulture);
            }

            var video = Regex.Match(text, @"Video:\s*([A-Za-z0-9_]+).*?,\s*([A-Za-z0-9_]+)(?:\([^)]*\))?,\s*(\d+)x(\d+).*?,\s*([0-9.]+)\s*fps", RegexOptions.Singleline);
            if (video.Success)
            {
                metadata.HasVideo = true;
                metadata.VideoCodec = video.Groups[1].Value;
                metadata.PixelFormat = video.Groups[2].Value;
                metadata.Width = int.Parse(video.Groups[3].Value);
                metadata.Height = int.Parse(video.Groups[4].Value);
                metadata.Fps = double.Parse(video.Groups[5].Value, CultureInfo.InvariantCulture);
            }

            var audio = Regex.Match(text, @"Audio:\s*([A-Za-z0-9_]+).*?,\s*(\d+)\s*Hz,\s*(mono|stereo|\d+\s+channels)", RegexOptions.Singleline);
            if (audio.Success)
            {
                metadata.HasAudio = true;
                metadata.AudioCodec = audio.Groups[1].Value;
                metadata.SampleRate = int.Parse(audio.Groups[2].Value);
                metadata.Channels = audio.Groups[3].Value == "mono" ? 1 : audio.Groups[3].Value == "stereo" ? 2 : int.Parse(Regex.Match(audio.Groups[3].Value, "\\d+").Value);
            }

            metadata.ColorSpace = text.IndexOf("bt709", StringComparison.OrdinalIgnoreCase) >= 0 ? "bt709" : "unknown";
            metadata.FormatName = metadata.HasVideo ? "mov,mp4,m4a,3gp,3g2,mj2" : "wav";
            if (!metadata.HasVideo && !metadata.HasAudio) throw new InvalidOperationException("FFmpeg found no audio or video stream");
            return metadata;
        }
    }
}
