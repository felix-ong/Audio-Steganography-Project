close all;
clear all;
Fs = 44100;
% Record 32s of information-embedded music in the air
recObj = audiorecorder(Fs, 16, 1); % 16-bit, 1 channel
disp('Start recording...');
recordblocking(recObj, 31);

y = getaudiodata(recObj);

% Shared information between encoder and decoder
encoding_base_freq = 17000;
start_end_signal_freq = 18000;
multiplier = 10;
time_window = 0.1;
num_samples_per_window = Fs*time_window; 
% Parameters specific to decoder
offset = 1000; % determines size of window

% Slide window until the start_end_signal is within window
% i+1000+0.5*Fs is the start position of the embedded message

message_start = 0;
for i = 1 : length(y)-offset
    window = y(i:i+offset);
    window_fft = fft(window, 2^nextpow2(length(window)));
    window_delta_f = Fs / length(window_fft);
    max_mag = max(abs(window_fft));
    pos = find(abs(window_fft) == max_mag);
    max_freq = (pos(1)-1)*window_delta_f;
    
    if abs(max_freq-start_end_signal_freq) <= 5
        disp("Start of encoded message "); 
        message_start = i+offset+0.5*Fs;
        disp(message_start);
        break
    end
end

% Slide window from end until the start_end_signal is not within window
% i+1000 is the end position of the embedded message
message_end = 0;

for i = length(y) - offset : -1 : 1
    window = y(i:i+offset);
    window_fft = fft(window, 2^nextpow2(length(window)));
    window_delta_f = Fs / length(window_fft);
    max_mag = max(abs(window_fft));
    pos = find(abs(window_fft) == max_mag);
    max_freq = (pos(1)-1)*window_delta_f;
    
    if abs(max_freq-start_end_signal_freq) <= 5
        disp("End of encoded message "); 
        message_end = i-0.5*Fs;
        disp(message_end);
        break
    end
end

coded_count = round((message_end - message_start) / (0.1*Fs));
disp(coded_count);
decoded = zeros(1, coded_count);
max_freqs = zeros(1, coded_count);

for i = 0 : coded_count-1
    window = y(message_start+num_samples_per_window*i:message_start+num_samples_per_window*(i+1));
    window_fft = fft(window, 2^nextpow2(length(window)));
    window_delta_f = Fs / length(window_fft);
    abs_window_fft = abs(window_fft);
    max_mag = max(abs_window_fft);
    pos = find(abs_window_fft==max_mag);
    max_freq = (pos(1) - 1) * window_delta_f;

    % Round off max_freq to the nearest 10 (since 10 is the multiplier)
    max_freq = round(max_freq/multiplier)*multiplier;
    max_freqs(i+1) = max_freq;
    decoded(i+1) = (max_freq-encoding_base_freq)/multiplier + 32;
end

decoded_message = char(decoded);
disp(decoded_message);
fname = 'A0217387W_FelixOngWeiCong_decodedMessage.txt';
fid = fopen(fname, 'w');
fprintf(fid, '%s', decoded_message);
fclose(fid);