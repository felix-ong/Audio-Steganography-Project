close all
clear all
%- Read the message to be encoded
fname = 'message_to_be_encoded.txt'; 
fid = fopen(fname,'r'); 
original_message = fgetl(fid);
fclose(fid);

%- Read the source music
sname = "source_music.wav";
[raw_y,Fs] = audioread(sname);

% Sampling frequency is 44100Hz, max frequency without aliasing (Nyquist frequency) is 22050Hz
% Highest audible frequency approx. 18000Hz, phone speakers play up to
% 20000Hz and laptop mics record up to 20000Hz, 2000Hz to use for message
dimensions = size(raw_y);

sampling_interval = 1 / Fs;
raw_length = length(raw_y);

% Take only the left channel since recording is done in single-channel
y_left = raw_y(:, 1)';
% Lowpass filter source music signal to remove inaudible frequencies
lowpass_freq = 15000;
filtered_y = lowpass(y_left,lowpass_freq,Fs);
% Threshold of 2000Hz set because the frequencies are not cut off sharply
% at 16000Hz
threshold = 2000;
encoding_base_freq = lowpass_freq + threshold;
start_end_signal_freq = 18000;
% Convert encoded_message into an array of char represented by their ASCII
% values
encoded_message = char(original_message);

% Since 0 to 31 will not appear in original message as specified, 
% can subtract 32 from ascii values to narrow the frequency range required
% to embed the message. 
% frequency of sine wave = encoding_base_freq + coded_value * 10
% 10 is chosen because +- 5 deviation from actual
% Maximum range of frequencies used to embed message: 16000 to 17900
% Beyond this range, unable to decode message with time window of 0.1
coded_values = encoded_message - 32;

% Set a fixed time window that each sine wave occupies
time_window = 0.1;

% Length of values to embed
coded_count = length(coded_values);
% expected_freqs = encoding_base_freq + coded_values * 10;
multiplier = 10;

concatenated_message_sig = [];
% Create a sine wave with a frequency outside the range of that used to 
% embed message to signal the start and end of the embedded message
% Occupies 0.5s but can be adjusted if needed
t=0:sampling_interval:0.5-sampling_interval;

start_end_signal = 2.5*sin(2*pi*start_end_signal_freq*t);

% Concatenate the sine waves encoding the message
t=0:sampling_interval:time_window-sampling_interval;
for i = 1:coded_count
    sig = 2.5*sin(2*pi*(encoding_base_freq+coded_values(i)*multiplier)*t);
    concatenated_message_sig = cat(2, concatenated_message_sig, sig);
end

% Concatenate the start_end_signal to both the start and end of the 
% concatenated message signal
concatenated_message_sig = [start_end_signal concatenated_message_sig start_end_signal];

% Add padding to ensure equal length
% padding added at the front since this also helps to provide some buffer
% if there is lag in recording after running the program
padding = zeros(1, raw_length - length(concatenated_message_sig));
concatenated_message_sig = [padding concatenated_message_sig];

% Add embedded message to the filtered source music signal
filtered_y = filtered_y + concatenated_message_sig;
filtered_y = filtered_y / max(abs(filtered_y));
result = 'A0217387W_FelixOngWeiCong_musicWithMessage.wav';
audiowrite(result, filtered_y, Fs);