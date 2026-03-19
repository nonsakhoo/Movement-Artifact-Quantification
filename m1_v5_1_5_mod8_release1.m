% v5.1.5
% 2025-08-04
% This version is copied from v5.1.5 from the main repository.
% This version is used for the paper review process. It’s not the final production version, but it’s exactly the same as the proposed methods in the paper. The code is hard-implemented and includes naive comments, and it’s not well-optimized for general use. Some algorithms are not fully implemented yet, and some processes are not well-organized. Some processes could be improved by using more advanced methods.
%
% If you find this work interesting, please wait for the better-organized and optimized code in the future. Also, please cite the paper after it’s published. Thank you for your interest and support!


function main()


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Preprocessing 1: Dataset Manipulation and Data Preparation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 1. Dataset Manipulation
    % Define base paths for macOS and Windows
    mac_base_path = '/Users/geeksloth/Desktop/Movement_Artifact_Dataset_2/cropped/';
    win_base_path = 'E:\Movement_Artifact_Dataset_2\cropped\';

    % Store only the folder names (relative paths)
    conf_dataset_folder = { ...
        'circle_128px_0_180', ...        % 1 <-- mainly used for this scope
        'circle_128px_15_195', ...       % 2
        'circle_128px_30_210', ...       % 3
        'circle_128px_45_225', ...       % 4
        'circle_128px_60_240', ...       % 5
        'circle_128px_75_255', ...       % 6
        'circle_128px_90_270', ...       % 7
        'circle_128px_105_285', ...      % 8
        'circle_128px_120_300', ...      % 9
        'circle_128px_135_315', ...      % 10
        'circle_128px_150_330', ...      % 11
        'circle_128px_165_345', ...      % 12
        'rectangle_256px_135_315', ...   % 13
        'rectangle_256px_150_330', ...   % 14
        'rectangle_256px_165_345', ...   % 15
        'circle_128px_mod', ...          % 16
        'triangle_0_180', ...            % 17
        'triangle_15_195', ...           % 18 <-- not ready
        'triangle_30_210', ...           % 19 <-- not ready
        'triangle_45_225', ...           % 20 <-- not ready
        'triangle_60_240', ...           % 21 <-- not ready
        'triangle_75_255', ...           % 22
        'triangle_90_270', ...           % 23 <-- not ready
        'triangle_105_285', ...          % 24
        'triangle_120_300', ...          % 25
        'triangle_135_315', ...          % 26
        'triangle_150_330', ...          % 27
        'triangle_165_345', ...          % 28
        'realworld_1', ...               % 29
    };

    % Detect OS and set base path accordingly
    if ispc
        base_path = win_base_path;
        %disp('Current OS: Windows');
    else
        base_path = mac_base_path;
        %disp('Current OS: macOS or other Unix-based');
    end

    % Construct full dataset directory paths
    conf_dataset_directory = cellfun(@(f) fullfile(base_path, f), conf_dataset_folder, 'UniformOutput', false);
    %conf_selected_directory = [1, 2, 14, 15];
    conf_selected_directory = [1,2,3,4,5,6,7,8,9,10,11,12]; % Select all directories by default
    conf_selected_images = [1,2,3,4,5,6,7,8,9,10,11]; % Select all images by default
    conf_grayscale_mode = true;         % Recommended to be true. The RGB channels are not implemented yet.
    conf_directions_of_enumeration = {'horizontal', 'diagonal', 'vertical', 'antidiagonal'};    % Direction of enumeration: 0, 45, 90, 135 representing horizontal, diagonal, vertical, antidiagonal respectively.
    conf_absolute_mode = false;         % Keep it false for now
    conf_dual_axis_mode = false;        % not implemented yet, but existed in the previous version
    conf_invert_mode = true;            % Recommended to be true for similarity to Ultrasound images
    conf_debug_mode = false;             % Debug mode for visualization
    conf_cropping = struct( ...
        'center_y', 720, ...        % manually adjusted based on the observed object center
        'x_offset', 0, ...          % manually adjusted
        'y_offset', 0, ...          % manually adjusted
        'width', 400, ...           % manually adjusted, default is 400, this value is obtained based on the observed area.
        'height', 400, ...          % manually adjusted, default is 400, this value is obtained based on the observed area.
        'padding', 200 ...          % for rotation purpose
    );

    % Algorithm 1: Movement Artifact Position Estimation (MAPE)
    % Minimum peak prominence for findpeaks function.
    % Higher values will result in fewer peaks being detected.
    % Lower values will result in more peaks being detected.
    conf_algo1_enable = true;
    conf_algo1_min_peak_prominence = 0.1;
    conf_algo1_enable_dynamic_prominence = true;    % Enable dynamic prominence adjustment based on the image size
    

    % Algorithm 2: Reference Origin Point Estimation (ROPE)
    conf_algo2_enable = true;                   % Enable ROPE algorithm
    conf_algo2_ema_alpha = 0.15;                % Smoothing factor for Exponential Moving Average
    % Probability (0 to 1) of the max peak value. 
    % The higher, the more detection sensitivity, but more noise.
    % The lower, the less detection sensitivity, but less noise.
    conf_algo2_slope_peak_threshold = 0.8; 
    
    % Algorithm 3: Movement Artifact Quantization (MAQ)
    conf_algo3_enable = true;                   % Enable MAQ algorithm
    conf_algo3_enable_adaptive_filtering = true;    % Recommend to be true. Proposed Adaptive Filtering. <-- working well.
    conf_algo3_maquantity_threshold = 60;       % Quantity threshold for filtering peaks (in pixels). The previous default was 30. <-- this can be improved with adaptive method.
    %conf_algo3_filtering_threshold_std = 0.1;   % Filtering threshold for the standard deviation of the slope <-- deprecated.
    conf_algo3_filtering_threshold_ma_slower_percent = 100; % 100% means the same length of the image_cropped_rotated
    conf_algo3_filtering_threshold_ma_faster_percent = 25;  % 25% of the length of the image_cropped_rotated
    conf_algo3_enable_corresponding_second_peak_filtering = false; % Default is false. Recommend to use the Adaptive Filtering instead. <-- deprecated.
    conf_algo3_enable_corresponding_slope_peak_filtering = false; % Default is false. Recommend to use the Adaptive Filtering instead. <-- deprecated.

    % Postprocessing 1: Visualization of MAPE, ROPE, and MAQ algorithms
    conf_post1_enable = true;                    % Enable postprocessing for MAPE, ROPE, and MAQ algorithms
    conf_post1_enable_visualization = false;     % Enable visualization for MAPE algorithm
    conf_post1_display_valid_nan_ratio = false;  % Enable visualization for valid to NaN ratio
    conf_post1_display_stats_display = false;    % Enable display of statistics

    % Algorithm 4: Look-At-Each-Axis <-- not important yet, and can be improved <-- seems to be working with the adaptive filtering.
    conf_algo4_enable = false;                   % Due to this algorithm is not important yet, it is also able to be false.
    conf_algo4_enable_visualization = true;
    conf_algo4_number_of_lines = 3;             % Must be odd number
    conf_algo4_line_average_mode = false;       % Default is true, but can be false for testing

    % Algorithm 5: Movement Artifact Direction Estimation (MADE) <-- This is already published.
    conf_algo5_enable = true;                   % If needed, it is also able to be false.
    conf_algo5_enable_visualization = false;     % Enable visualization for debugging
    conf_algo5_plot_relative_position = false;   % Plot the relative position of the MAQ to the image_cropped
    conf_algo5_maq_std_boost_factor = 1; % Boost factor for standard deviation
    conf_algo5_made_origin_relative = false;


    % Parameters for global statistics
    gt_direction_deg = [];
    gt_direction_deg_complement = [];
    gt_velocity = [];
    est_direction_deg = zeros(length(conf_selected_directory), length(conf_selected_images));
    est_direction_error_deg = zeros(length(conf_selected_directory), length(conf_selected_images));
    est_weighted_distance_px = zeros(length(conf_selected_directory), length(conf_selected_images));

    % 2. Image Loading
    for directory_index = conf_selected_directory
        dataset_directory_selected = conf_dataset_directory{directory_index};
        image_paths = load_image_paths_from_folder(dataset_directory_selected);

        disp('======================================================');
        % Extract groundtruth_shape, groundtruth_angle, and groundtruth_angle_complement from folder name
        folder_name = conf_dataset_folder{directory_index};
        tokens = regexp(folder_name, '^(?<groundtruth_shape>\w+)_(?<size>\d+)px_(?<groundtruth_angle>\d+)_(?<groundtruth_angle_complement>\d+)', 'names');
        if ~isempty(tokens)
            groundtruth_shape = tokens.groundtruth_shape;
            groundtruth_angle = str2double(tokens.groundtruth_angle);
            groundtruth_angle_complement = str2double(tokens.groundtruth_angle_complement);
        else
            groundtruth_shape = '';
            groundtruth_angle = NaN;
            groundtruth_angle_complement = NaN;
        end

        % Append to global statistics as a new row
        if ~ismember(groundtruth_angle, gt_direction_deg)
            gt_direction_deg = [gt_direction_deg; groundtruth_angle];
        end
        if ~ismember(groundtruth_angle_complement, gt_direction_deg_complement)
            gt_direction_deg_complement = [gt_direction_deg_complement; groundtruth_angle_complement];
        end

        fprintf('Shape: %s\nMA Direction (degrees): %g°, Complementary: %g°\n', ...
                        groundtruth_shape, groundtruth_angle, groundtruth_angle_complement);

        for index = 1:length(image_paths)
            if ismember(index, conf_selected_images)
                image = imread(image_paths{index});
                current_image_path = image_paths{index};

                %current_gt_velocity = [];
                current_est_direction_deg = [];
                current_est_direction_error_deg = [];
                current_est_weighted_distance_px = [];

                % Extract groundtruth_velocity from image filename (e.g., "0.2.jpg" means 0.2 m/s)
                [~, current_image_name, ext] = fileparts(current_image_path);
                tokens = regexp(current_image_name, '^(?<groundtruth_velocity>[\d\.]+)', 'names');
                if ~isempty(tokens)
                    groundtruth_velocity = str2double(tokens.groundtruth_velocity);
                else
                    groundtruth_velocity = NaN;
                end
                disp('------------------------------------------------------');
                disp(['Ground truth [image: ', current_image_name, ext, ', direction : ', num2str(groundtruth_angle), '°, velocity: ', num2str(groundtruth_velocity), ' m/s]']);

                % Append to global statistics
                % Append current_gt_velocity to gt_velocity if it is not already in the list
                if ~ismember(groundtruth_velocity, gt_velocity)
                    gt_velocity = [gt_velocity; groundtruth_velocity];
                end

                if conf_grayscale_mode
                    % Global variables for each direction of enumeration
                    post1_algo1_bias = [];
                    post1_algo1_variance = [];
                    post1_algo2_bias = [];
                    post1_algo2_variance = [];
                    post1_algo3_bias = [];
                    post1_algo3_variance = [];
                    post1_algo3_maquantity_mean = [];
                    post1_algo3_maquantity_std = [];
                    post1_algo3_valid_to_nan_ratio = [];

                    image_grayscale = rgb2gray(image);
                    center_x = size(image_grayscale, 2) / 2;


                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Preprocessing 2: For MAPE, ROPE, and MAQ algorithms
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % 1. Cropping
                    image_cropped = crop_image(image_grayscale, ...
                                        center_x + conf_cropping.x_offset, ...
                                        conf_cropping.center_y + conf_cropping.y_offset, ...
                                        conf_cropping.width, ...
                                        conf_cropping.height);
                    % 2. Inversion
                    if conf_invert_mode
                        image_cropped = imcomplement(image_cropped);
                    end

                    if conf_debug_mode
                        figure('Name', 'Cropped Image');
                        imshow(image_cropped);
                        title('Cropped Image');
                    end

                    if 0
                        disp('------------------------------------------------------');
                        disp('2.1. Directional MAQ Preparation:');
                    end

                    % 3. Direction of Enumeration
                    for direction_of_enumeration_index = 1:length(conf_directions_of_enumeration)
                        direction_of_enumeration = conf_directions_of_enumeration(direction_of_enumeration_index);
                        if strcmp(direction_of_enumeration, 'horizontal')
                            image_cropped_rotated = image_cropped;
                        elseif strcmp(direction_of_enumeration, 'diagonal')                           
                            rows = size(image_cropped, 1); % Number of rows in the matrix
                            cols = size(image_cropped, 2); % Number of columns in the matrix
                            image_cropped_rotated = cell(rows + cols - 1, 1); % Preallocate cell array for diagonals
                            for row = 1:rows
                                for col = 1:cols
                                    % Calculate the diagonal index as the sum of the row and column indices minus 1. This ensures that elements on the same diagonal share the same index.
                                    diagonal_index = row + col - 1; 
                                    % If the diagonal cell is empty, initialize it as an empty uint8 array to store elements of the diagonal.
                                    if isempty(image_cropped_rotated{diagonal_index})
                                        image_cropped_rotated{diagonal_index} = uint8([]); 
                                    end
                                    % Append the current matrix element to the corresponding diagonal in the cell array.
                                    image_cropped_rotated{diagonal_index} = [image_cropped_rotated{diagonal_index}, image_cropped(row, col)]; 
                                end
                            end

                            % Debug: Plot diagonals as cell array (before flipping)
                            if conf_debug_mode && false
                                figure('Name', 'Diagonals (cell array, before flipping)');
                                for i = 1:length(image_cropped_rotated)
                                    subplot(ceil(sqrt(length(image_cropped_rotated))), ceil(sqrt(length(image_cropped_rotated))), i);
                                    plot(double(image_cropped_rotated{i}));
                                    title(['Diag ', num2str(i)]);
                                    axis tight;
                                end
                            end

                            % Flip the diagonals to match the original image orientation
                            image_cropped_rotated_flipped = cell(length(image_cropped_rotated), 1); % Preallocate cell array for diagonals
                            for i = 1:length(image_cropped_rotated)
                                image_cropped_rotated_flipped{i} = flip(image_cropped_rotated{i});
                            end
                            image_cropped_rotated = image_cropped_rotated_flipped;

                            % Debug: Plot diagonals as cell array (after flipping)
                            if conf_debug_mode && false
                                figure('Name', 'Diagonals (cell array, after flipping)');
                                for i = 1:length(image_cropped_rotated)
                                    subplot(ceil(sqrt(length(image_cropped_rotated))), ceil(sqrt(length(image_cropped_rotated))), i);
                                    plot(double(image_cropped_rotated{i}));
                                    title(['Diag ', num2str(i)]);
                                    axis tight;
                                end
                            end

                            % Convert the cell array to a 2D matrix for visualization
                            max_diagonal_length = max(cellfun(@length, image_cropped_rotated));
                            image_cropped_rotated_matrix_centered = zeros(length(image_cropped_rotated), max_diagonal_length, 'like', double(image_cropped));
                            for i = 1:length(image_cropped_rotated)
                                diagonal = image_cropped_rotated{i};
                                start_col = ceil((max_diagonal_length - length(diagonal)) / 2) + 1; % Center-align the diagonals
                                image_cropped_rotated_matrix_centered(i, start_col:start_col + length(diagonal) - 1) = double(diagonal); % Store diagonal as uint8
                            end

                            % Debug: Plot the centered diagonal matrix before cropping
                            if conf_debug_mode
                                figure('Name', 'Diagonal Matrix Centered (before cropping)');
                                imagesc(image_cropped_rotated_matrix_centered);
                                colormap gray; colorbar; axis image;
                                title('Diagonal Matrix Centered (before cropping)');
                            end

                            % Cropping the image_cropped_rotated_matrix_centered to remove padding zeros and NaN values
                            % Calculate the center of the image
                            center_row = size(image_cropped_rotated_matrix_centered, 1) / 2;
                            center_col = size(image_cropped_rotated_matrix_centered, 2) / 2;
                            % Define the cropping dimensions
                            crop_width = size(image_cropped_rotated_matrix_centered, 2) / 2;
                            crop_height = size(image_cropped_rotated_matrix_centered, 1) / 2;
                            % Calculate the cropping boundaries
                            start_row = round(center_row - crop_height / 2);
                            end_row = round(center_row + crop_height / 2 - 1);
                            start_col = round(center_col - crop_width / 2);
                            end_col = round(center_col + crop_width / 2 - 1);
                            % Perform the cropping
                            image_cropped_rotated_matrix_centered = image_cropped_rotated_matrix_centered(start_row:end_row, start_col:end_col);

                            % Debug: Plot the cropped diagonal matrix
                            if conf_debug_mode
                                figure('Name', 'Diagonal Matrix Centered (after cropping)');
                                imagesc(image_cropped_rotated_matrix_centered);
                                colormap gray; colorbar; axis image;
                                title('Diagonal Matrix Centered (after cropping)');
                            end

                            image_cropped_rotated = image_cropped_rotated_matrix_centered;
                        elseif strcmp(direction_of_enumeration, 'vertical')
                            % Transpose method
                            % image_cropped_rotated = image_cropped'; % Transpose the image for 90-direction_of_enumeration direction_of_enumeration
                            % Rotate method
                            image_cropped_rotated = rot90(image_cropped, 1); % Rotate the image for 90-direction_of_enumeration direction_of_enumeration
                        elseif strcmp(direction_of_enumeration, 'antidiagonal')
                            rows = size(image_cropped, 1); % Number of rows in the matrix
                            cols = size(image_cropped, 2); % Number of columns in the matrix
                            image_cropped_rotated = cell(rows + cols - 1, 1); % Preallocate cell array for anti-diagonals
                            for row = 1:rows
                                for col = 1:cols
                                    % Calculate the anti-diagonal index as the difference between the column and row indices plus the number of rows.
                                    anti_diagonal_index = col - row + rows;
                                    % If the anti-diagonal cell is empty, initialize it as an empty uint8 array to store elements of the anti-diagonal.
                                    if isempty(image_cropped_rotated{anti_diagonal_index})
                                        image_cropped_rotated{anti_diagonal_index} = uint8([]);
                                    end
                                    % Append the current matrix element to the corresponding anti-diagonal in the cell array.
                                    image_cropped_rotated{anti_diagonal_index} = [image_cropped_rotated{anti_diagonal_index}, image_cropped(row, col)];
                                end
                            end
                            max_anti_diagonal_length = max(cellfun(@length, image_cropped_rotated));
                            image_cropped_rotated_matrix_centered = zeros(length(image_cropped_rotated), max_anti_diagonal_length, 'like', double(image_cropped));
                            for i = 1:length(image_cropped_rotated)
                                anti_diagonal = image_cropped_rotated{i};
                                start_col = ceil((max_anti_diagonal_length - length(anti_diagonal)) / 2) + 1; % Center-align the anti-diagonals
                                image_cropped_rotated_matrix_centered(i, start_col:start_col + length(anti_diagonal) - 1) = double(anti_diagonal); % Store anti-diagonal as uint8
                            end
                            
                            % Debug: Plot the centered antidiagonal matrix before cropping
                            if conf_debug_mode
                                figure('Name', 'Antidiagonal Matrix Centered (before cropping)');
                                imagesc(image_cropped_rotated_matrix_centered);
                                colormap gray; colorbar; axis image;
                                title('Antidiagonal Matrix Centered (before cropping)');
                            end

                            % Cropping the image_cropped_rotated_matrix_centered to remove padding zeros and NaN values
                            % Calculate the center of the image
                            center_row = size(image_cropped_rotated_matrix_centered, 1) / 2;
                            center_col = size(image_cropped_rotated_matrix_centered, 2) / 2;
                            % Define the cropping dimensions
                            crop_width = size(image_cropped_rotated_matrix_centered, 2) / 2;
                            crop_height = size(image_cropped_rotated_matrix_centered, 1) / 2;
                            % Calculate the cropping boundaries
                            start_row = round(center_row - crop_height / 2);
                            end_row = round(center_row + crop_height / 2 - 1);
                            start_col = round(center_col - crop_width / 2);
                            end_col = round(center_col + crop_width / 2 - 1);
                            % Perform the cropping
                            image_cropped_rotated_matrix_centered = image_cropped_rotated_matrix_centered(start_row:end_row, start_col:end_col);
                            image_cropped_rotated = flipud(image_cropped_rotated_matrix_centered); % Flip the matrix vertically to correct the y-axis orientation
                            
                            % Debug: Plot the cropped antidiagonal matrix
                            if conf_debug_mode
                                figure('Name', 'Antidiagonal Matrix Centered (after cropping)');
                                imagesc(image_cropped_rotated_matrix_centered);
                                colormap gray; colorbar; axis image;
                                title('Antidiagonal Matrix Centered (after cropping)');
                            end
                        else
                            image_cropped_rotated = image_cropped;
                        end

                        % Normalization
                        image_normalized = NaN(size(image_cropped_rotated));
                        for row = 1:size(image_cropped_rotated, 1)  % 1 means row-wise, 2 means column-wise
                            line = image_cropped_rotated(row, :);
                            signal = double(line);
                            signal_mean = mean(signal);
                            signal = signal - signal_mean;
                            signal_sd = std(signal);
                            signal = signal / signal_sd;
                            % Store the normalized signal into the corresponding row
                            image_normalized(row, :) = signal;
                        end


                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % Algorithm 1: Movement Artifact Position Estimation (MAPE)
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % 1. Enumerate each line of normalized image
                        % 2. Compute the correlation analysis of the signal with itself
                        % 3. Identify potential peaks of the correlation coefficient
                        % 4. Find the significant second peak   
                        % 5. Flip the second peak lags for symmetry analysis      
                        % Outputs:
                        algo1_corr_all = zeros(size(image_normalized, 1), 2 * size(image_normalized, 2) - 1); % Preallocate based on xcorr output size
                        algo1_lags_all = zeros(size(image_normalized, 1), 2 * size(image_normalized, 2) - 1); % Preallocate based on xcorr output size
                        algo1_second_peak_value_all = NaN(size(image_normalized, 1), 1); % Preallocate with NaN
                        algo1_second_peak_location_all = NaN(size(image_normalized, 1), 1); % Preallocate with NaN   
                        algo1_second_peak_location_all_flip = NaN(size(image_normalized, 1), 1); % Preallocate with NaN         
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        if conf_algo1_enable
                            disp('[MAPE] This code section will be updated after publication.');
                            %disp('Algorithm 1 completed.');
                        end % End of conf_algo1_enable

                        % 5. Flip the second peak lags for symmetry analysis
                        for i = 1:length(algo1_second_peak_location_all)
                            if algo1_second_peak_location_all(i) < 0
                                algo1_second_peak_location_all_flip(i) = -1 * (size(image_normalized, 2) - abs(algo1_second_peak_location_all(i)));
                            else
                                algo1_second_peak_location_all_flip(i) = size(image_normalized, 2) - algo1_second_peak_location_all(i);
                            end
                        end


                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % Algorithm 2: Reference Origin Point Estimation (ROPE)
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % This algorithm focuses on identifying slope peaks to determine reference points in the signal.
                        % 1. Normalize the signal <-- use the normalized signal from the previous step
                        % 2. Calculate the exponential moving average of the normalized signal
                        % 3. Calculate the slope of the moving average
                        % 4. Find the peak of slope to determint the reference point.
                        % 5. Suppress non-significant slope peaks based on a threshold <-- experimental, may have other better ways
                        % Outputs:
                        algo2_signal_ema_all = zeros(size(image_normalized, 1), size(image_normalized, 2)); % Preallocate based on image dimensions
                        algo2_signal_slope_all = zeros(size(image_normalized, 1), size(image_normalized, 2) - 1); % Preallocate based on size
                        algo2_slope_peak_location_all = NaN(size(image_normalized, 1), 1); % Preallocate with NaN
                        algo2_slope_peak_value_all = NaN(size(image_normalized, 1), 1); % Preallocate with NaN
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        if conf_algo2_enable
                            disp('[ROPE] This code section will be updated after publication.');
                            %disp('Algorithm 2 completed.');
                        end % End of conf_algo2_enable


                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % Algorithm 3: Movement Artifact Quantification (MAQ)
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % 1. [Optional] Filter out the second peak lags that are not related with the slope peaks.
                        % 2. [Optional] Filter out the slope peak locations that are not related with the second peak lags.
                        % 3. Proposed Adaptive Filtering: Filter out the slope peaks based on the moving average of the lower peak values.
                        %    3.1. Calculate the standard deviation of each slopes of algo2_signal_slope_all
                        %    3.2. Calculate the lower peak of the standard deviation of the slope
                        %    3.3. Making up the invalid values.
                        %    3.4. Calculate the criterion trend lines.
                        %    3.5. Operate the filtering.
                        % 4. Calculate the Movement Artifact Quantity (MAq)


                        % Outputs:
                        algo3_maquantity_mean = NaN; % Initialize with NaN
                        algo3_maquantity_std = NaN; % Initialize with NaN
                        algo3_valid_to_nan_ratio = NaN; % Initialize with NaN
                        algo3_second_peak_location_all_flip =algo1_second_peak_location_all_flip; % Initialize with NaN
                        algo3_filtering_kernel = NaN;
                        algo3_second_peak_location_all = algo1_second_peak_location_all;
                        algo3_slope_peak_location_all = algo2_slope_peak_location_all; % Initialize with NaN
                        algo3_slope_std_all = NaN(size(algo2_signal_slope_all, 1), 1); % Standard deviations of the slopes
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        if conf_algo3_enable
                            ddisp('[MAQ] This code section will be updated after publication.');
                        end % End of conf_algo3_enable


                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % Postprocessing 1: Visualization of MAPE, ROPE, and MAQ algorithms
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % 1. Correction for vertical direction
                        %    - Counter-rotate the image and related data for vertical direction.
                        % 2. Calculate statistics
                        %    - Compute mean, standard deviation, and valid/NaN ratio for MAQ.
                        % 3. Display results
                        %    - Print calculated statistics for debugging and analysis.
                        % 4. Bias and variance calculations
                        %    - Compute bias and variance for MAPE, ROPE, and MAQ algorithms.
                        % 5. Append results to global variables
                        %    - Store calculated statistics for further analysis.
                        % 6. Visualization
                        %    - Display cropped images, slope signals, and standard deviation plots.
                        %    - Overlay second peak locations, flipped second peak locations, and slope peak locations.
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        if conf_post1_enable
                            % Correction
                            if strcmp(direction_of_enumeration, 'vertical')
                                image_cropped_rotated = rot90(image_cropped_rotated, -1); % Counter-rotate the image for 90-degree direction_of_enumeration
                                algo1_second_peak_location_all = rot90(algo1_second_peak_location_all, -1); % Counter-rotate the second peak location for 90-degree direction_of_enumeration
                                algo3_second_peak_location_all = rot90(algo3_second_peak_location_all, -1); % Counter-rotate the second peak location for 90-degree direction_of_enumeration
                                algo3_second_peak_location_all_flip = rot90(algo3_second_peak_location_all_flip, -1); % Counter-rotate the second peak location for 90-degree direction_of_enumeration
                                algo2_slope_peak_location_all = rot90(algo2_slope_peak_location_all, -1); % Rotate the slope peak index for -90-degree direction_of_enumeration
                                algo3_slope_peak_location_all = rot90(algo3_slope_peak_location_all, -1); % Counter-rotate the slope filtering kernel for 90-degree direction_of_enumeration
                            end

                            % Calculate statistics
                            abs_maquantity_all = abs(maquantity_all);               % Take absolute values before calculation
                            algo3_maquantity_mean = mean(abs_maquantity_all, 'omitnan');  % Omit NaN values
                            algo3_maquantity_std = std(abs_maquantity_all, 'omitnan');    % Omit NaN values
                            valid_values_count = sum(~isnan(maquantity_all)); % Count valid (non-NaN) values
                            nan_values_count = sum(isnan(maquantity_all));   % Count NaN values
                            algo3_valid_to_nan_ratio = valid_values_count / (valid_values_count + nan_values_count); % Calculate ratio
                            if 0
                                fprintf('%s \t mean-MAQ (pixels): %.2f \t StdDev: %.2f\n', ...
                                        char(direction_of_enumeration), algo3_maquantity_mean, algo3_maquantity_std);
                            end
                            % Calculate bias and variance for Algorithm 1, 2, and Algorithm 3 outputs
                            % Algorithm 1: Bias and Variance of Second Peak Locations
                            algo1_bias = mean(algo1_second_peak_location_all, 'omitnan'); % Mean of second peak locations
                            algo1_variance = var(algo1_second_peak_location_all, 'omitnan'); % Variance of second peak locations

                            % Algorithm 2: Bias and Variance of Slope Peak Indices
                            algo2_bias = mean(algo2_slope_peak_location_all, 'omitnan'); % Mean of slope peak indices
                            algo2_variance = var(algo2_slope_peak_location_all, 'omitnan'); % Variance of slope peak indices

                            % Algorithm 3: Bias and Variance of Movement Artifact Quantities
                            algo3_bias = mean(maquantity_all, 'omitnan');
                            algo3_variance = var(maquantity_all, 'omitnan');

                            % Display the calculated bias and variance
                            if conf_post1_display_stats_display
                                fprintf('Algo1 MAPE: Bias=%.2f, Var=%.2f | Algo2 ROPE: Bias=%.2f, Var=%.2f | Algo3 MAQ: Bias=%.2f, Var=%.2f\n', ...
                                    algo1_bias, algo1_variance, algo2_bias, algo2_variance, algo3_bias, algo3_variance);
                            end

                            % Display ratio of valid to NaN values of each algorithm.
                            if conf_post1_display_valid_nan_ratio
                                fprintf('Valid/NaN Ratios - Algo1: %.2f, Algo2: %.2f, Algo3: %.2f\n', ...
                                    length(find(~isnan(algo1_second_peak_location_all))) / size(image_normalized, 1), ...
                                    length(find(~isnan(algo2_slope_peak_location_all))) / size(image_normalized, 1), ...
                                    algo3_valid_to_nan_ratio);
                            end

                            % Append the results into the global variables
                            post1_algo1_bias = [post1_algo1_bias; algo1_bias];
                            post1_algo1_variance = [post1_algo1_variance; algo1_variance];
                            post1_algo2_bias = [post1_algo2_bias; algo2_bias];
                            post1_algo2_variance = [post1_algo2_variance; algo2_variance];
                            post1_algo3_bias = [post1_algo3_bias; algo3_bias];
                            post1_algo3_variance = [post1_algo3_variance; algo3_variance];
                            post1_algo3_maquantity_mean = [post1_algo3_maquantity_mean; algo3_maquantity_mean];
                            post1_algo3_maquantity_std = [post1_algo3_maquantity_std; algo3_maquantity_std];
                            post1_algo3_valid_to_nan_ratio = [post1_algo3_valid_to_nan_ratio; algo3_valid_to_nan_ratio];

                            % Visulization for each direction of enumeration of MAPE (red and blue), ROPE (green), and MAQ (not yet shown).
                            if conf_post1_enable_visualization
                                figure('Name', current_image_path, 'NumberTitle', 'off', 'Units', 'pixels', 'Position', [600 0 1240 1080])
                                fig_row = 2;
                                fig_col = 4;
                                ax = subplot(fig_row, fig_col, 1);
                                colormap(ax, 'gray');
                                imshow(image_cropped);
                                [~, two_depth_path, ~] = fileparts(fileparts(current_image_path));
                                title(['', fullfile(two_depth_path, current_image_name)], 'Interpreter', 'none');

                                ax = subplot(fig_row, fig_col, 2);
                                colormap(ax, 'gray');
                                set(gca, 'YDir', 'reverse'); % Flip y-axis
                                imagesc(algo1_lags_all(1, :), 1:size(algo1_corr_all, 1), algo1_corr_all);
                                hold on;
                                for i = 1:length(algo1_second_peak_location_all)
                                    %plot(algo1_second_peak_location_all(i), i, 'r.');
                                    if conf_absolute_mode
                                        plot(abs(algo1_second_peak_location_all(i)), i, 'r.');
                                    else 
                                        if algo1_second_peak_location_all(i) > 0
                                            plot(algo1_second_peak_location_all(i), i, 'r.');
                                        elseif algo1_second_peak_location_all(i) < 0
                                            plot(algo1_second_peak_location_all(i), i, 'b.');
                                        else
                                            %plot(algo1_second_peak_location_all(i), i, 'r.');
                                        end
                                    end
                                end
                                title('Algo1: MAPE');
                                hold off;

                                ax = subplot(fig_row, fig_col, 3);
                                colormap(ax, 'gray');
                                if strcmp(direction_of_enumeration, 'horizontal')
                                    imshow(image_cropped_rotated);
                                elseif strcmp(direction_of_enumeration, 'diagonal') 
                                    imagesc(uint8(image_cropped_rotated), 'AlphaData', ~isnan(image_cropped_rotated));
                                elseif strcmp(direction_of_enumeration, 'vertical')
                                    imshow(image_cropped_rotated);
                                elseif strcmp(direction_of_enumeration, 'antidiagonal')
                                    imagesc(uint8(image_cropped_rotated), 'AlphaData', ~isnan(image_cropped_rotated));
                                else
                                    error('Rotation not supported!');
                                end
                                hold on;
                                if true
                                    for i = 1:length(algo1_second_peak_location_all)
                                        if algo1_second_peak_location_all(i) > 0
                                            plot(algo1_second_peak_location_all(i), i, 'r.');
                                        elseif algo1_second_peak_location_all(i) < 0
                                            plot(abs(algo1_second_peak_location_all(i)), i, 'b.');
                                        else
                                            %plot(algo1_second_peak_location_all(i), i, 'r.');
                                        end
                                    end
                                end
                                for i = 1:length(algo1_second_peak_location_all_flip)
                                    if algo1_second_peak_location_all_flip(i) > 0
                                        plot(algo1_second_peak_location_all_flip(i), i, 'r.');
                                    elseif algo1_second_peak_location_all_flip(i) < 0
                                        plot(abs(algo1_second_peak_location_all_flip(i)), i, 'b.');
                                    else
                                        %plot(algo1_second_peak_location_all_flip(i), i, 'r.');
                                    end
                                end
                                title('Algo1: MAPE');
                                hold off;
                                axis on;

                                ax = subplot(fig_row, fig_col, 4);
                                colormap(ax, 'gray'); 
                                if strcmp(direction_of_enumeration, 'horizontal')
                                    imshow(image_cropped_rotated);
                                    hold on;
                                    for i = 1:length(algo2_slope_peak_location_all)
                                        plot(algo2_slope_peak_location_all(i), i, 'g.');
                                    end
                                elseif strcmp(direction_of_enumeration, 'diagonal') 
                                    imagesc(uint8(image_cropped_rotated), 'AlphaData', ~isnan(image_cropped_rotated));
                                    hold on;
                                    for i = 1:length(algo2_slope_peak_location_all)
                                        plot(algo2_slope_peak_location_all(i), i, 'g.');
                                    end
                                elseif strcmp(direction_of_enumeration, 'vertical')
                                    imshow(image_cropped_rotated);
                                    hold on;
                                    for i = 1:length(algo2_slope_peak_location_all)
                                        plot(i, algo2_slope_peak_location_all(i), 'g.');
                                    end
                                elseif strcmp(direction_of_enumeration, 'antidiagonal')
                                    imagesc(uint8(image_cropped_rotated), 'AlphaData', ~isnan(image_cropped_rotated));
                                    hold on;
                                    for i = 1:length(algo2_slope_peak_location_all)
                                        plot(algo2_slope_peak_location_all(i), i, 'g.');
                                    end
                                else
                                    error('Rotation not supported!');
                                end
                                title('Algo2: ROPE');
                                hold off;
                                axis on;


                                ax = subplot(fig_row, fig_col, 5);
                                colormap(ax, 'gray');
                                imagesc(algo2_signal_ema_all, 'AlphaData', ~isnan(algo2_signal_ema_all));
                                colormap gray;
                                %colorbar;
                                title('Algo3: MAQ (EMA)');
                                xlabel('Column Index');
                                ylabel('Row Index');
                                axis on;

                                ax = subplot(fig_row, fig_col, 6);
                                colormap(ax, 'gray');
                                imagesc(algo2_signal_slope_all, 'AlphaData', ~isnan(algo2_signal_slope_all));
                                %colorbar;
                                title('Algo3: MAQ (Slope)');
                                xlabel('Column Index');
                                ylabel('Row Index');
                                axis on;

                                ax = subplot(fig_row, fig_col, 7);
                                colormap(ax, 'gray');
                                plot(algo3_slope_std_all, 1:length(algo3_slope_std_all), 'LineWidth', 1);
                                set(gca, 'YDir', 'reverse'); % Flip the y-axis
                                ylim([1, length(algo3_slope_std_all)]); % Limit the y-axis
                                title('Algo3: MAQ (Adaptive Filtering)');
                                ylabel('Row Index');
                                xlabel('Standard Deviation');
                                grid on;
                                hold on;
                                
                                if conf_algo3_enable_adaptive_filtering
                                    % Plot the lower peak locations
                                    if ~isnan(algo2_lower_peak_locations)
                                        plot(algo2_lower_peak_values, algo2_lower_peak_locations, 'ro', 'MarkerSize', 8, 'LineWidth', 1);
                                    end

                                    % Plot the filled lower peak values
                                    if ~isnan(algo2_lower_peak_values_filled)
                                        plot(algo2_lower_peak_values_filled, 1:length(algo2_lower_peak_values_filled), 'm-', 'LineWidth', 1);
                                    end

                                    % Plot the moving average of lower peak values (slower)
                                    if ~isnan(algo2_lower_peak_values_ma_slower)
                                        plot(algo2_lower_peak_values_ma_slower, 1:length(algo2_lower_peak_values_ma_slower), 'g--', 'LineWidth', 1);
                                    end
                                    % Plot the moving average of lower peak values (faster)
                                    if ~isnan(algo2_lower_peak_values_ma_faster)
                                        plot(algo2_lower_peak_values_ma_faster, 1:length(algo2_lower_peak_values_ma_faster), 'b--', 'LineWidth', 1);
                                    end
                                    legend('Slope Std Dev', 'Lower Peak Location','FilledLPL', 'Moving Avg (Slower)', 'Moving Avg (Faster)', 'Location', 'best');
                                else
                                    legend('Slope Std Dev', 'Lower Peak Location', 'Location', 'best');
                                end
                                %legend('algo3_slope_std_all', '[algo2_lower_peak_values, algo2_lower_peak_locations]', 'algo2_lower_peak_values_ma_slower', 'algo2_lower_peak_values_ma_faster', 'Location', 'best');
                                hold off;

                                ax = subplot(fig_row, fig_col, 8);
                                colormap(ax, 'gray');
                                if strcmp(direction_of_enumeration, 'horizontal')
                                    imshow(image_cropped_rotated);
                                    hold on;
                                    for i = 1:length(algo3_second_peak_location_all)
                                        if algo3_second_peak_location_all(i) > 0
                                            plot(algo3_second_peak_location_all(i), i, 'r.');
                                        elseif algo3_second_peak_location_all(i) < 0
                                            plot(abs(algo3_second_peak_location_all(i)), i, 'b.');
                                        else
                                            %plot(algo3_second_peak_location_all(i), i, 'r.');
                                        end
                                    end
                                    for i = 1:length(algo3_second_peak_location_all_flip)
                                        if algo3_second_peak_location_all_flip(i) > 0
                                            plot(algo3_second_peak_location_all_flip(i), i, 'r.');
                                        elseif algo3_second_peak_location_all_flip(i) < 0
                                            plot(abs(algo3_second_peak_location_all_flip(i)), i, 'b.');
                                        else
                                            %plot(algo3_second_peak_location_all_flip(i), i, 'r.');
                                        end
                                    end
                                    for i = 1:length(algo3_slope_peak_location_all)
                                        plot(algo3_slope_peak_location_all(i), i, 'g.');
                                    end
                                elseif strcmp(direction_of_enumeration, 'diagonal') 
                                    imagesc(uint8(image_cropped_rotated), 'AlphaData', ~isnan(image_cropped_rotated));
                                    hold on;
                                    for i = 1:length(algo3_second_peak_location_all)
                                        if algo3_second_peak_location_all(i) > 0
                                            plot(algo3_second_peak_location_all(i), i, 'r.');
                                        elseif algo3_second_peak_location_all(i) < 0
                                            plot(abs(algo3_second_peak_location_all(i)), i, 'b.');
                                        else
                                            %plot(algo3_second_peak_location_all(i), i, 'r.');
                                        end
                                    end
                                    for i = 1:length(algo3_second_peak_location_all_flip)
                                        if algo3_second_peak_location_all_flip(i) > 0
                                            plot(algo3_second_peak_location_all_flip(i), i, 'r.');
                                        elseif algo3_second_peak_location_all_flip(i) < 0
                                            plot(abs(algo3_second_peak_location_all_flip(i)), i, 'b.');
                                        else
                                            %plot(algo3_second_peak_location_all_flip(i), i, 'r.');
                                        end
                                    end
                                    for i = 1:length(algo3_slope_peak_location_all)
                                        plot(algo3_slope_peak_location_all(i), i, 'g.');
                                    end
                                elseif strcmp(direction_of_enumeration, 'vertical')
                                    imshow(image_cropped_rotated);
                                    hold on;
                                    for i = 1:length(algo3_second_peak_location_all)
                                        if algo3_second_peak_location_all(i) > 0
                                            plot(i, algo3_second_peak_location_all(i), 'r.');
                                        elseif algo3_second_peak_location_all(i) < 0
                                            plot(i, abs(algo3_second_peak_location_all(i)), 'b.');
                                        else
                                            %plot(algo3_second_peak_location_all(i), i, 'r.');
                                        end
                                    end
                                    for i = 1:length(algo3_second_peak_location_all_flip)
                                        if algo3_second_peak_location_all_flip(i) > 0
                                            plot(i, algo3_second_peak_location_all_flip(i), 'r.');
                                        elseif algo3_second_peak_location_all_flip(i) < 0
                                            plot(i, abs(algo3_second_peak_location_all_flip(i)), 'b.');
                                        else
                                            %plot(algo3_second_peak_location_all_flip(i), i, 'r.');
                                        end
                                    end
                                    for i = 1:length(algo3_slope_peak_location_all)
                                        plot(i, algo3_slope_peak_location_all(i), 'g.');
                                    end
                                elseif strcmp(direction_of_enumeration, 'antidiagonal')
                                    imagesc(uint8(image_cropped_rotated), 'AlphaData', ~isnan(image_cropped_rotated));
                                    hold on;
                                    for i = 1:length(algo3_second_peak_location_all)
                                        if algo3_second_peak_location_all(i) > 0
                                            plot(algo3_second_peak_location_all(i), i, 'r.');
                                        elseif algo3_second_peak_location_all(i) < 0
                                            plot(abs(algo3_second_peak_location_all(i)), i, 'b.');
                                        else
                                            %plot(algo3_second_peak_location_all(i), i, 'r.');
                                        end
                                    end
                                    for i = 1:length(algo3_second_peak_location_all_flip)
                                        if algo3_second_peak_location_all_flip(i) > 0
                                            plot(algo3_second_peak_location_all_flip(i), i, 'r.');
                                        elseif algo3_second_peak_location_all_flip(i) < 0
                                            plot(abs(algo3_second_peak_location_all_flip(i)), i, 'b.');
                                        else
                                            %plot(algo3_second_peak_location_all_flip(i), i, 'r.');
                                        end
                                    end
                                    for i = 1:length(algo3_slope_peak_location_all)
                                        plot(algo3_slope_peak_location_all(i), i, 'g.');
                                    end
                                    
                                else
                                    error('Rotation not supported!');
                                end
                                title([direction_of_enumeration, ', mean-MAQ (pixels): ', num2str(algo3_maquantity_mean, '%.2f')]);
                                hold off;
                                axis on;
                                waitfor(gcf);
                            end % End of conf_post1_enable_visualization
                        end % End of conf_post1_enable
                    end % End of enumeration of conf_directions_of_enumeration

                    if 0
                        disp('------------------------------------------------------');
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Algorithm 5: Movement Artifact Direction Estimation (MADE)
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % This algorithm estimates the direction of movement artifacts in the image.
                    % It uses the results from the previous algorithms to determine the most likely direction of artifacts.
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    if conf_algo5_enable

                        for dir_idx = 1:length(conf_directions_of_enumeration)
                            direction_of_enumeration = conf_directions_of_enumeration(dir_idx);
                            if strcmp(direction_of_enumeration, 'horizontal')
                                algo5_maq_horizontal = post1_algo3_maquantity_mean(dir_idx);
                                algo5_std_horizontal = post1_algo3_maquantity_std(dir_idx);
                            elseif strcmp(direction_of_enumeration, 'diagonal')
                                algo5_maq_diagonal = post1_algo3_maquantity_mean(dir_idx);
                                algo5_std_diagonal = post1_algo3_maquantity_std(dir_idx);
                            elseif strcmp(direction_of_enumeration, 'vertical')
                                algo5_maq_vertical = post1_algo3_maquantity_mean(dir_idx);
                                algo5_std_vertical = post1_algo3_maquantity_std(dir_idx);
                            elseif strcmp(direction_of_enumeration, 'antidiagonal')
                                algo5_maq_antidiagonal = post1_algo3_maquantity_mean(dir_idx);
                                algo5_std_antidiagonal = post1_algo3_maquantity_std(dir_idx);
                            else
                                error('Unsupported direction_of_enumeration: %d', direction_of_enumeration);
                            end
                        end

                        %%%%%%%%%%%% MAQ values Prioritization %%%%%%%%%%%%
                        % This section prioritizes the standard deviation values of the MAQ in a specific order.
                        % The order is: horizontal, diagonal, vertical, antidiagonal.
                        % The standard deviation values are sorted and swapped to ensure the desired order.
                        % The smallest value is more significant in determining the direction of movement artifacts.
                        %%%%%%%%%%%%
                        % Boost the standard deviation values
                        std_values = [algo5_std_horizontal, algo5_std_diagonal, algo5_std_vertical, algo5_std_antidiagonal] * conf_algo5_maq_std_boost_factor;
                        [std_sorted, sorted_indices] = sort(std_values);
                        % Swap the smallest and highest values
                        std_values(sorted_indices(1)) = std_sorted(4); % Smallest becomes highest
                        std_values(sorted_indices(4)) = std_sorted(1); % Highest becomes smallest
                        % Swap the mid-lower and mid-higher values
                        std_values(sorted_indices(2)) = std_sorted(3); % Mid-lower becomes mid-higher
                        std_values(sorted_indices(3)) = std_sorted(2); % Mid-higher becomes mid-lower
                        % Assign the swapped values back to the variables
                        algo5_std_horizontal_new = std_values(1);
                        algo5_std_diagonal_new = std_values(2);
                        algo5_std_vertical_new = std_values(3);
                        algo5_std_antidiagonal_new = std_values(4);
                        if conf_algo5_plot_relative_position
                            center_x = round(size(image_cropped, 2) / 2);
                            center_y = round(size(image_cropped, 1) / 2);
                            center_z = 0;
                        else
                            center_x = 0;
                            center_y = 0;
                            center_z = 0;
                        end

                        % Define the MAQ points in 3D space
                        % The points are defined in a 3D space with x, y, and z coordinates.
                        points = {
                            [center_x + algo5_maq_horizontal, center_y, algo5_std_horizontal_new], ... % Horizontal
                            [center_x + algo5_maq_diagonal, center_y + algo5_maq_diagonal, algo5_std_diagonal_new], ... % Diagonal
                            [center_x, center_y + algo5_maq_vertical, algo5_std_vertical_new], ... % Vertical
                            [center_x - algo5_maq_antidiagonal, center_y + algo5_maq_antidiagonal, algo5_std_antidiagonal_new], ... % Antidiagonal
                            [center_x - algo5_maq_horizontal, center_y, algo5_std_horizontal_new], ... % Horizontal complement
                            [center_x - algo5_maq_diagonal, center_y - algo5_maq_diagonal, algo5_std_diagonal_new], ... % Diagonal complement
                            [center_x, center_y - algo5_maq_vertical, algo5_std_vertical_new], ... % Vertical complement
                            [center_x + algo5_maq_antidiagonal, center_y - algo5_maq_antidiagonal, algo5_std_antidiagonal_new] ... % Antidiagonal complement  
                        };

                        % Prepare the origin point for the 3D space
                        if conf_algo5_made_origin_relative
                            % Extract x, y, and z coordinates
                            x_coords = points_matrix(:, 1);
                            y_coords = points_matrix(:, 2);
                            z_coords = points_matrix(:, 3);
                            % Replace NaN or Inf values with dummy values. This to prevent errors in some functions.
                            x_coords(isnan(x_coords) | isinf(x_coords)) = 0; % Replace with 0 or any desired dummy value
                            y_coords(isnan(y_coords) | isinf(y_coords)) = 0; % Replace with 0 or any desired dummy value
                            z_coords(isnan(z_coords) | isinf(z_coords)) = 0; % Replace with 0 or any desired dummy value
                            xyz_origin = [0, 0, min(z_coords)];
                        else % Typically, the origin is at [0, 0, 0]
                            xyz_origin = [0, 0, 0];
                        end

                        % Convert points to a matrix for easier manipulation
                        points_matrix = cell2mat(points');  

                        if 0
                            %disp('------------------------------------------------------');
                            disp('2.2 MAQ Values Prioritization (higher value is more significant) and 3D Space Mapping:');
                            disp(['Horizontal: ', num2str(algo5_std_horizontal_new, '%.2f')]);
                            disp(['Diagonal: ', num2str(algo5_std_diagonal_new, '%.2f')]);
                            disp(['Vertical: ', num2str(algo5_std_vertical_new, '%.2f')]);
                            disp(['Antidiagonal: ', num2str(algo5_std_antidiagonal_new, '%.2f')]);
                            disp(['points_matrix size: ', mat2str(size(points_matrix)), ', class: ', class(points_matrix)]);
                            disp('points_matrix (first 4 rows):');
                            disp(points_matrix(1:min(4,end), :));
                            disp('------------------------------------------------------');
                        end
                        %%%%%%%%%%%%



                        %%%%%%%%%%%% Farthest Point Calculation %%%%%%%%%%%%
                        % -- Currently not used in the algorithm, but kept for future reference.
                        % This section calculates the farthest point from the origin in the points_matrix.
                        % The farthest point is determined by calculating the Euclidean distance from the origin to each point.
                        % The two farthest points are selected for further analysis.                        
                        % These steps are for the farthest point visualization purposes.
                        %%%%%%%%%%%%
                        % Prepare data for 3D vector distance calculation
                        %reference_point = xyz_origin;
                        points_field = points_matrix(1:floor(size(points_matrix, 1) / 2), :);
                        % Calculate the Euclidean distance from the reference point to all points
                        distances = sqrt(sum((points_field - repmat(xyz_origin, size(points_field, 1), 1)).^2, 2));
                        % Sort the distances and get the indices of the two largest distances
                        [sorted_distances, sorted_indices] = sort(distances, 'descend');
                        % Get the two farthest points
                        farthest_points = points_field(sorted_indices(1), :);
                        farthest_points_complement = points_matrix(sorted_indices(1) + floor(size(points_matrix, 1) / 2), :);
                        
                        if 0
                            disp('[Optional] Farthest Point Calculation:');
                            disp(['Farthest Point: ', mat2str(farthest_points)]);
                            disp(['Farthest Point Complement: ', mat2str(farthest_points_complement)]);
                            disp('------------------------------------------');
                        end
                        %%%%%%%%%%%%

                        %%%%%%%%%%%% Optimal Triplet Selection %%%%%%%%%%%%
                        % Find the 3 adjacent points that contain the farthest point among them
                        % This loop checks all possible triplets of adjacent points (with wrap-around)
                        % and selects the triplet whose sum of distances from the origin is maximal.
                        % The indices of the best triplet are then used to extract the corresponding points from points_matrix.
                        %%%%%%%%%%%%
                        % Find the 3 adjacent points that contain the farthest point among them
                        num_points = size(points_matrix, 1);
                        
                        % Calculate distances from origin to all points
                        all_distances = sqrt(sum((points_matrix - repmat(xyz_origin, num_points, 1)).^2, 2));
                        
                        % Find the best triplet of adjacent points that contains the farthest point
                        % and where all three points are as far as possible from origin
                        max_triplet_total_distance = -1;
                        best_triplet_start_idx = 1;
                        
                        for i = 1:num_points
                            % Get three adjacent points (with wrap-around)
                            idx1 = i;
                            idx2 = mod(i, num_points) + 1;
                            idx3 = mod(i + 1, num_points) + 1;
                            
                            % Get distances for all three points in this triplet
                            triplet_distances = [all_distances(idx1), all_distances(idx2), all_distances(idx3)];
                            
                            % Calculate total distance (sum of all three distances)
                            total_distance_in_triplet = sum(triplet_distances);
                            
                            % Update best triplet if this one has a larger total distance
                            if total_distance_in_triplet > max_triplet_total_distance
                                max_triplet_total_distance = total_distance_in_triplet;
                                best_triplet_start_idx = i;
                            end
                        end
                        
                        % Get the indices of the best triplet (maintain original ordering)
                        idx1 = best_triplet_start_idx;
                        idx2 = mod(best_triplet_start_idx, num_points) + 1;
                        idx3 = mod(best_triplet_start_idx + 1, num_points) + 1;

                        % Get the coordinates of the three points in 3D (maintain original ordering)
                        p1 = points_matrix(idx1, :);      % first point (3D)
                        p2 = points_matrix(idx2, :);      % second point (3D)
                        p3 = points_matrix(idx3, :);      % third point (3D)

                        optimal_triplet = [p1; p2; p3];

                        if 0
                            disp('2.3 Optimal 3D Triplet Selection:');
                            disp(['Farthest Point: [', num2str(p1(1), '%.2f'), ', ', num2str(p1(2), '%.2f'), ', ', num2str(p1(3), '%.2f'), ']']);
                            disp(['Neighbor Point 1: [', num2str(p2(1), '%.2f'), ', ', num2str(p2(2), '%.2f'), ', ', num2str(p2(3), '%.2f'), ']']);
                            disp(['Neighbor Point 2: [', num2str(p3(1), '%.2f'), ', ', num2str(p3(2), '%.2f'), ', ', num2str(p3(3), '%.2f'), ']']);
                            disp('------------------------------------------------------');
                        end
                        %%%%%%%%%%%%

                        %%%%%%%%%%%% Direction Estimation %%%%%%%%%%%%
                        % This section determines the estimated direction of movement artifacts
                        % by selecting the three adjacent points (triplet) with the largest total distance from the origin.
                        % It then computes the center of mass of these points to represent the dominant direction.
                        % The angle of this center of mass is calculated in 2D (x-y plane) and normalized to [0, 360) degrees.
                        % The complementary angle is also computed for reference.
                        % This approach provides a robust estimation of the artifact direction based on the spatial distribution of MAQ points.
                        %%%%%%%%%%%%

                        % Calculate the center of mass (mean of the 3D coordinates)
                        center_of_mass = mean([p1; p2; p3], 1); % 1x3 vector

                        %disp('Center of Mass of Farthest Point and Neighbors (3D):');
                        %disp(center_of_mass);

                        % Calculate the angle of the center_of_mass point
                        angle_CenterOfMass = atan2d(center_of_mass(2), center_of_mass(1));
                        if angle_CenterOfMass < 0
                            angle_CenterOfMass = angle_CenterOfMass + 360; % Normalize angle to be in [0, 360) degrees
                        end
                        % Calculate the complementary angle
                        angle_CenterOfMass_complement = mod(angle_CenterOfMass + 180, 360); % Complementary angle in [0, 360) degrees
                        %fprintf('Angle of Center of Mass: %.2f°, Complementary: %.2f°\n', angle_CenterOfMass, angle_CenterOfMass_complement);
                        %%%%%%%%%%%%

                        if 0
                            disp('2.4 Direction Estimation:');
                            disp(['CoM (3D): [', num2str(center_of_mass(1), '%.2f'), ', ', num2str(center_of_mass(2), '%.2f'), ', ', num2str(center_of_mass(3), '%.2f'), ']']);
                            disp(['Angle of CoM: ', num2str(angle_CenterOfMass, '%.2f'), '°']);
                            disp(['Complementary Angle of CoM: ', num2str(angle_CenterOfMass_complement, '%.2f'), '°']);
                            disp('---------------------------------------');
                        end

                        %%%%%%%%%%%% Line Matrix Creation %%%%%%%%%%%%
                        % This section creates a line matrix that connects each point in the points_matrix with its neighbors.
                        % The lines are used to calculate the final distance to the estimated direction of movement artifacts.
                        % The lines are also used to visualize the points in 3D space.
                        %%%%%%%%%%%%
                        % Create a line matrix to store the lines connecting each point with its neighbors
                        neighbor_lines_matrix = zeros(size(points_matrix, 1), 6); % Preallocate for efficiency
                        for i = 1:size(points_matrix, 1)
                            next_idx = mod(i, size(points_matrix, 1)) + 1; % Circular indexing to connect the last point to the first
                            neighbor_lines_matrix(i, :) = [points_matrix(i, :), points_matrix(next_idx, :)];
                        end
                        %disp('Neighbor Lines Matrix:');
                        %disp(neighbor_lines_matrix);

                        % This is for visualization only
                        % Store lines connecting xyz_origin with every point in points_matrix
                        origin_lines_matrix = zeros(size(points_matrix, 1), 6); % Preallocate for efficiency
                        for i = 1:size(points_matrix, 1)
                            origin_lines_matrix(i, :) = [xyz_origin, points_matrix(i, :)];
                        end
                        %%%%%%%%%%%%

                        %%%%%%%%%%%% Calculate the Weighted Distance %%%%%%%%%%%%
                        % This section calculates the weighted distance from the origin to the estimated point on the neighboring line which is closest to the center_of_mass point.
                        % The distance is calculated using the Euclidean distance formula.
                        % The steps are as follows:
                        % 1. Line Matrix Formation.
                        % 2. Line Segment Identification.
                        % 3. Ray-Line Intersection Calculation.
                        % 4. Calculate the weighted distance from the origin to the intersection point
                        %%%%%%%%%%%%
                        
                        % 1. Line Matrix Formation
                        % Wrap-around neighbor_lines_matrix for circular adjacency
                        wrapped_neighbor_lines_matrix = neighbor_lines_matrix;
                        wrapped_neighbor_lines_matrix(end+1, :) = [neighbor_lines_matrix(end, 4:6), neighbor_lines_matrix(1, 1:3)];
                        % Find the intersection point based on angle_CenterOfMass
                        % Determine which line segment the angle falls into
                        % Each line covers 45 degrees: 0-45, 45-90, 90-135, 135-180, 180-225, 225-270, 270-315, 315-360
                        num_neighbor_lines = size(wrapped_neighbor_lines_matrix, 1) - 1; % Exclude the duplicate last line
                        angle_per_segment = 360 / num_neighbor_lines; % Should be 45 degrees for 8 lines

                        % 2. Line Segment Identification
                        % Find which line segment contains the angle
                        segment_index = floor(angle_CenterOfMass / angle_per_segment) + 1;
                        % Handle edge case where angle is exactly 360 degrees
                        if segment_index > num_neighbor_lines
                            segment_index = 1;
                        end
                        % Extract the start and end points of the line segment
                        segment_start_3d = wrapped_neighbor_lines_matrix(segment_index, 1:3); % Start point [x1, y1, z1]
                        segment_end_3d = wrapped_neighbor_lines_matrix(segment_index, 4:6);   % End point [x2, y2, z2]

                        % 3. Ray-Line Intersection Calculation
                        % Create a ray from origin in the direction of angle_CenterOfMass
                        ray_direction_2d = [cosd(angle_CenterOfMass), sind(angle_CenterOfMass)]; % 2D direction vector
                        ray_origin_2d = xyz_origin(1:2); % Origin in 2D (x, y only)
                        
                        % Line segment in 2D
                        segment_start_2d = segment_start_3d(1:2);
                        segment_end_2d = segment_end_3d(1:2);
                        segment_vector_2d = segment_end_2d - segment_start_2d;
                        
                        % Solve for intersection using parametric equations:
                        % Ray: ray_origin_2d + ray_param * ray_direction_2d
                        % Line: segment_start_2d + segment_param * segment_vector_2d
                        % At intersection: ray_origin_2d + ray_param * ray_direction_2d = segment_start_2d + segment_param * segment_vector_2d
                        
                        % Set up matrix equation to solve for parameters ray_param and segment_param
                        intersection_matrix = [ray_direction_2d', -segment_vector_2d'];
                        intersection_rhs = (segment_start_2d - ray_origin_2d)';
                        
                        % Check if lines are parallel
                        if abs(det(intersection_matrix)) < 1e-10
                            % Lines are parallel, use the midpoint as fallback
                            segment_param = 0.5; % Use midpoint
                            ray_param = 0;      % Assign a default value to ray_param
                        else
                            % Solve for parameters
                            intersection_params = intersection_matrix \ intersection_rhs;
                            ray_param = intersection_params(1);
                            segment_param = intersection_params(2);
                        end
                        
                        segment_param_clamped = max(0, min(1, segment_param));
                        
                        % Calculate the intersection point in 3D by interpolating between segment_start_3d and segment_end_3d
                        intersection_point = segment_start_3d + segment_param_clamped * (segment_end_3d - segment_start_3d);
                        
                        %fprintf('Segment Index: %d (covers %.1f° to %.1f°)\n', segment_index, ...
                        %        (segment_index-1)*angle_per_segment, segment_index*angle_per_segment);
                        %fprintf('Intersection Point: [%.2f, %.2f, %.2f]\n', ...
                        %        intersection_point(1), intersection_point(2), intersection_point(3));
                        
                        % 4. Calculate the weighted distance from the origin to the intersection point
                        weighted_distance = norm(intersection_point - xyz_origin);
                        %fprintf('Weighted Distance to Intersection Point: %.2f\n', weighted_distance);
                        %%%%%%%%%%%%

                        if 0
                            disp('2.5 Weighted Distance Calculation:');
                            disp("Neighbor Lines Matrix:");
                            disp(neighbor_lines_matrix);
                            disp(['Segment Index: ', num2str(segment_index), ' (covers ', num2str((segment_index-1)*angle_per_segment, '%.1f'), '° to ', num2str(segment_index*angle_per_segment, '%.1f'), '°)']);
                            disp(['Intersection Point: [', num2str(intersection_point(1), '%.2f'), ', ', num2str(intersection_point(2), '%.2f'), ', ', num2str(intersection_point(3), '%.2f'), ']']);
                            disp(['Weighted Distance to Intersection Point: ', num2str(weighted_distance, '%.2f pixels')]);
                            disp('------------------------------------------------------');
                        end
                        
                        if 1
                            % Calculate estimated MA direction error based on ground truth
                            if abs(angle_CenterOfMass - groundtruth_angle) < abs(angle_CenterOfMass - groundtruth_angle_complement)
                                estimated_angle_error = angle_CenterOfMass - groundtruth_angle;
                            else
                                estimated_angle_error = angle_CenterOfMass - groundtruth_angle_complement;
                            end
                            %disp('------------------------------------------------------');
                            fprintf('Estimated [MA direction: %.2f°, error: %.2f°, weighted distance: %.2f px]\n', ...
                                angle_CenterOfMass, estimated_angle_error, weighted_distance);

                            % Display the current_ variables before appending
                            if 0
                                disp('Current Estimated Variables Before Appending:');
                                disp(['current_est_direction_deg: ', mat2str(current_est_direction_deg')]);
                                disp(['current_est_direction_error_deg: ', mat2str(current_est_direction_error_deg')]);
                                disp(['current_est_weighted_distance_px: ', mat2str(current_est_weighted_distance_px')]);
                                disp('---------------------------------------');
                            end
                            % Append results to the est variables
                            current_est_direction_deg = [current_est_direction_deg; angle_CenterOfMass];
                            current_est_direction_error_deg = [current_est_direction_error_deg; estimated_angle_error];
                            current_est_weighted_distance_px = [current_est_weighted_distance_px; weighted_distance];

                            % Display the current_ variables after appending
                            if 0
                                disp('Current Estimated Variables After Appending:');
                                disp(['current_est_direction_deg: ', mat2str(current_est_direction_deg')]);
                                disp(['current_est_direction_error_deg: ', mat2str(current_est_direction_error_deg')]);
                                disp(['current_est_weighted_distance_px: ', mat2str(current_est_weighted_distance_px')]);
                                disp('---------------------------------------');
                            end

                        end

                        %%%%%%%%%%%% Visualization of MADE Results %%%%%%%%%%%%
                        if conf_algo5_enable_visualization
                            axis_limits = [5, 5];
                            if 0 % conf_algo5_enable_visualization
                                % First figure: Cropped image
                                figure;
                                colormap('gray');
                                imagesc(image_cropped);
                                [~, two_depth_path, ~] = fileparts(fileparts(current_image_path));
                                title(['', fullfile(two_depth_path, current_image_name)], 'Interpreter', 'none');
                                xlabel('X-axis');
                                ylabel('Y-axis');
                                axis on;
                                grid on;
                                axis equal; % Keep aspect ratio
                                xlim([1, size(image_cropped, 2)]);
                                ylim([1, size(image_cropped, 1)]);
                            end

                            % Second figure: 3D MADE visualization
                            figure;
                            colormap('parula');
                            % Plot the xyz_origin point
                            if 1
                                scatter3(xyz_origin(1), xyz_origin(2), xyz_origin(3), 150, 'g', 'filled', 'DisplayName', 'MAQ Origin');
                            end
                            if 0
                                text(xyz_origin(1), xyz_origin(2), xyz_origin(3)-0.25, 'MAQ Origin', 'Color', 'g', 'FontSize', 8, 'FontWeight', 'bold');
                            end
                            hold on;

                            % Plot the farthest points with green dots
                            if 0
                                scatter3(farthest_points(1), farthest_points(2), farthest_points(3), 50, 'g', 'filled', 'DisplayName', 'Farthest Point');
                                text(farthest_points(1), farthest_points(2), farthest_points(3) + 0.25, 'Farthest Point', 'Color', 'g', 'FontSize', 8, 'FontWeight', 'bold');
                                scatter3(farthest_points_complement(1), farthest_points_complement(2), farthest_points_complement(3), 50, 'g', 'filled', 'DisplayName', 'Farthest Point Complement');
                                text(farthest_points_complement(1), farthest_points_complement(2), farthest_points_complement(3) + 0.25, 'Farthest Point Complement', 'Color', 'g', 'FontSize', 8, 'FontWeight', 'bold');
                            end
                            
                            % Plot the lines connecting the points to the origin
                            if 0
                                for i = 1:size(origin_lines_matrix, 1)
                                    plot3([origin_lines_matrix(i, 1), origin_lines_matrix(i, 4)], ...
                                        [origin_lines_matrix(i, 2), origin_lines_matrix(i, 5)], ...
                                        [origin_lines_matrix(i, 3), origin_lines_matrix(i, 6)], ...
                                        'k-', 'LineWidth', 1.5); % Black line
                                end
                            end

                            % Plot the neighbor lines connecting each point to its neighbors
                            if 1
                                for i = 1:size(neighbor_lines_matrix, 1)
                                    plot3([neighbor_lines_matrix(i, 1), neighbor_lines_matrix(i, 4)], ...
                                        [neighbor_lines_matrix(i, 2), neighbor_lines_matrix(i, 5)], ...
                                        [neighbor_lines_matrix(i, 3), neighbor_lines_matrix(i, 6)], ...
                                        'b-', 'LineWidth', 1.5); % Blue line
                                end
                            end

                            % Plot the points in 3D space
                            if 1
                                scatter3(points_matrix(:, 1), points_matrix(:, 2), points_matrix(:, 3), 50, 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r', 'DisplayName', 'MAQ Points');
                            end

                            % Plot the optimal triplet
                            if 1
                                scatter3(optimal_triplet(:, 1), optimal_triplet(:, 2), optimal_triplet(:, 3), 150, 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'm', 'DisplayName', 'Optimal Triplet');
                            end

                            % Plot the left, center, and right neighbors of the optimal triplet
                            if 0
                                for triplet_idx = 1:size(optimal_triplet, 1)
                                    scatter3(optimal_triplet(triplet_idx, 1), optimal_triplet(triplet_idx, 2), optimal_triplet(triplet_idx, 3), ...
                                        50, 'filled', 'DisplayName', ['Triplet Point ', num2str(triplet_idx)]);
                                    text(optimal_triplet(triplet_idx, 1), optimal_triplet(triplet_idx, 2), optimal_triplet(triplet_idx, 3) + 0.25, ...
                                        ['Triplet ', num2str(triplet_idx)], 'Color', 'k', 'FontSize', 8, 'FontWeight', 'bold');
                                end
                            end

                            % Draw the red line from xyz_origin to the farthest points
                            if 0
                                plot3([xyz_origin(1), farthest_points(1)], ...
                                    [xyz_origin(2), farthest_points(2)], ...
                                    [xyz_origin(3), farthest_points(3)], ...
                                    'r-', 'LineWidth', 2, 'DisplayName', 'Line to Farthest Point');
                                plot3([xyz_origin(1), farthest_points_complement(1)], ...
                                    [xyz_origin(2), farthest_points_complement(2)], ...
                                    [xyz_origin(3), farthest_points_complement(3)], ...
                                    'r-', 'LineWidth', 2, 'DisplayName', 'Line to Farthest Point Complement');
                            end

                            % Draw the blue line from xyz_origin to the center of mass
                            if 0
                                plot3([xyz_origin(1), center_of_mass(1)], ...
                                    [xyz_origin(2), center_of_mass(2)], ...
                                    [xyz_origin(3), center_of_mass(3)], ...
                                    'b--', 'LineWidth', 2, 'DisplayName', 'Line to Center of Mass');
                            end

                            % Plot the center of mass point
                            if 1
                                scatter3(center_of_mass(1), center_of_mass(2), center_of_mass(3), 150, 'b', 'filled', 'DisplayName', 'Center of Mass');
                                %text(center_of_mass(1), center_of_mass(2), center_of_mass(3) + 0.25, 'Center of Mass', 'Color', 'b', 'FontSize', 8, 'FontWeight', 'bold');
                            end

                            % Plot the intersection point on the neighboring line
                            if 1
                                scatter3(intersection_point(1), intersection_point(2), intersection_point(3), 50, 'k', 'filled', 'DisplayName', 'Intersection Point');
                                %text(intersection_point(1), intersection_point(2), intersection_point(3) + 0.25, 'Intersection Point', 'Color', 'k', 'FontSize', 8, 'FontWeight', 'bold');
                            end

                            % Draw a rectangle from the xyz_origin to the intersection point
                            if 0
                                % Define the rectangle vertices
                                rect_vertices = [ ...
                                    xyz_origin; ... % 1. origin
                                    [xyz_origin(1), xyz_origin(2), intersection_point(3)]; ... % 2. origin x/y, intersection z
                                    intersection_point; ... % 3. intersection point
                                    [intersection_point(1), intersection_point(2), xyz_origin(3)] ... % 4. intersection x/y, origin z
                                ];
                                % Draw the rectangle using fill3
                                fill3(rect_vertices(:, 1), rect_vertices(:, 2), rect_vertices(:, 3), 'r', 'FaceAlpha', 1, 'DisplayName', 'Rectangle to Intersection');
                                % Draw the rectangle edges using plot3
                                plot3(rect_vertices([1:4 1], 1), rect_vertices([1:4 1], 2), rect_vertices([1:4 1], 3), 'k-.', 'LineWidth', 2, 'DisplayName', 'Rectangle Edges');
                            end
                            
                            % Draw a rectangle from the xyz_origin to the first point of the optimal triplet
                            if 0
                                % Define the rectangle vertices using segment_start_3d
                                rect_vertices = [ ...
                                    xyz_origin; ... % 1. origin
                                    [xyz_origin(1), xyz_origin(2), segment_start_3d(3)]; ... % 2. origin x/y, segment_start z
                                    segment_start_3d; ... % 3. segment_start_3d point
                                    [segment_start_3d(1), segment_start_3d(2), xyz_origin(3)] ... % 4. segment_start x/y, origin z
                                ];
                                % Draw the rectangle using fill3
                                fill3(rect_vertices(:, 1), rect_vertices(:, 2), rect_vertices(:, 3), 'r', 'FaceAlpha', 1, 'DisplayName', 'Rectangle to Segment Start');
                                % Draw the rectangle edges using plot3
                                plot3(rect_vertices([1:4 1], 1), rect_vertices([1:4 1], 2), rect_vertices([1:4 1], 3), 'k:', 'LineWidth', 2, 'DisplayName', 'Rectangle Edges');
                            end

                            % Draw a rectangle from the xyz_origin to the last point of the optimal triplet
                            if 0
                                % Define the rectangle vertices using segment_end_3d
                                rect_vertices = [ ...
                                    xyz_origin; ... % 1. origin
                                    [xyz_origin(1), xyz_origin(2), segment_end_3d(3)]; ... % 2. origin x/y, segment_end z
                                    segment_end_3d; ... % 3. segment_end_3d point
                                    [segment_end_3d(1), segment_end_3d(2), xyz_origin(3)] ... % 4. segment_end x/y, origin z
                                ];
                                % Draw the rectangle using fill3
                                fill3(rect_vertices(:, 1), rect_vertices(:, 2), rect_vertices(:, 3), 'r', 'FaceAlpha', 1, 'DisplayName', 'Rectangle to Segment End');
                                % Draw the rectangle edges using plot3
                                plot3(rect_vertices([1:4 1], 1), rect_vertices([1:4 1], 2), rect_vertices([1:4 1], 3), 'k:', 'LineWidth', 2, 'DisplayName', 'Rectangle Edges');
                            end

                            % Plot the line from the origin to the intersection point
                            if 1
                                plot3([xyz_origin(1), intersection_point(1)], ...
                                    [xyz_origin(2), intersection_point(2)], ...
                                    [xyz_origin(3), intersection_point(3)], ...
                                    'k--', 'LineWidth', 2, 'DisplayName', 'Line to Intersection Point');
                            end

                            % Set the view and labels
                            xlabel('MAQ-x');
                            ylabel('MAQ-y');
                            zlabel('MAQ-reliability');
                            %title('Movement Artifact Direction Estimation (MADE)');
                            % Use the angle of CoM and Weighted Distance in the title
                            %title(sprintf('MADE: \\theta: %.2f°, q: %.2f', angle_CenterOfMass, weighted_distance));

                            grid on;
                            shading interp; % Smooth shading for better visualization
                            view(3); % Set the default view to 3D
                            axis equal;
                            xlim([min(points_matrix(:,1))-axis_limits(1), max(points_matrix(:,1))+axis_limits(2)]);
                            ylim([min(points_matrix(:,2))-axis_limits(1), max(points_matrix(:,2))+axis_limits(2)]);
                            hold off;
                            waitfor(gcf);
                        end % End of conf_algo5_enable_visualization
                    end % End of conf_algo5_enable
                    % Ensure current_est_direction_deg is a row vector
                    est_direction_deg(directory_index, index) = current_est_direction_deg(end);
                    est_direction_error_deg(directory_index, index) = current_est_direction_error_deg(end);
                    est_weighted_distance_px(directory_index, index) = current_est_weighted_distance_px(end);
                end % End of if conf_grayscale_mode
                %disp(' ');
            end % End of if ismember(index, conf_selected_images)
            % Display a blank line for better readability in the console
        end % End of for index = 1:length(image_paths)
        disp('======================================================');
    end % End of for directory_index = conf_selected_directory

    % Display global statistics and their dimensions
    fprintf('gt_direction_deg = [');
    fprintf('%.0f; ', gt_direction_deg);
    fprintf('];\n');
    fprintf('gt_direction_deg_complement = [');
    fprintf('%.0f; ', gt_direction_deg_complement);
    fprintf('];\n');
    fprintf('gt_velocity = [');
    fprintf('%.1f; ', gt_velocity);
    fprintf('];\n');
    fprintf('est_direction_deg = [\n');
    for i = 1:size(est_direction_deg, 1)
        for j = 1:size(est_direction_deg, 2)
            fprintf('%.2f', est_direction_deg(i, j));
            if j == size(est_direction_deg, 2)
                fprintf(';\n');
            else
                fprintf(', ');
            end
        end
    end
    fprintf('];\n');
    fprintf('est_direction_error_deg = [\n');
    for i = 1:size(est_direction_error_deg, 1)
        for j = 1:size(est_direction_error_deg, 2)
            fprintf('%.2f', est_direction_error_deg(i, j));
            if j == size(est_direction_error_deg, 2)
                fprintf(';\n');
            else
                fprintf(', ');
            end
        end
    end
    fprintf('];\n');
    fprintf('est_weighted_distance_px = [\n');
    for i = 1:size(est_weighted_distance_px, 1)
        for j = 1:size(est_weighted_distance_px, 2)
            fprintf('%.2f', est_weighted_distance_px(i, j));
            if j == size(est_weighted_distance_px, 2)
                fprintf(';\n');
            else
                fprintf(', ');
            end
        end
    end
    fprintf('];\n');

    % Updated visualization function
    plot_direction_error_and_weighted_distance(gt_direction_deg, gt_direction_deg_complement, gt_velocity, est_direction_error_deg, est_weighted_distance_px);
end % End of function main()


% Helper function to flip second peak locations
function flipped = flip_second_peak_locations(locations, image_width)
    flipped = NaN(size(locations)); % Initialize with NaN
    for i = 1:length(locations)
        if locations(i) < 0
            flipped(i) = -1 * (image_width - abs(locations(i)));
        else
            flipped(i) = image_width - locations(i);
        end
    end
end

function filtered = filter_invalid_values(values, reference, threshold)
    % FILTER_INVALID_VALUES Filters out invalid values based on a reference and threshold.
    %
    %   filtered = FILTER_INVALID_VALUES(values, reference, threshold)
    %
    %   This function takes an array of input values and filters out invalid
    %   entries based on the following criteria:
    %     1. The value or its corresponding reference is NaN.
    %     2. The absolute difference between the value and its reference exceeds
    %        the specified threshold.
    %
    %   Parameters:
    %     values    - A numeric array containing the input values to be filtered.
    %     reference - A numeric array of the same size as `values`, serving as
    %                 the reference for comparison.
    %     threshold - A scalar value specifying the maximum allowable absolute
    %                 difference between `values` and `reference`.
    %
    %   Returns:
    %     filtered  - A numeric array of the same size as `values`, where invalid
    %                 entries are replaced with NaN. Valid entries remain unchanged.
    %
    %   Mathematical Representation:
    %     Let `v_i` and `r_i` represent the elements of `values` and `reference` arrays, respectively.
    %     The filtering condition can be expressed as:
    %       filtered_i = NaN, if isnan(v_i) OR isnan(r_i) OR |v_i - r_i| > threshold
    %       filtered_i = v_i, otherwise
    %
    %   Example:
    %     values = [1.2, 3.4, NaN, 5.6];
    %     reference = [1.0, 3.5, 4.0, 5.5];
    %     threshold = 0.5;
    %     filtered = filter_invalid_values(values, reference, threshold);
    %     % filtered = [1.2, NaN, NaN, 5.6]
    filtered = values; % Copy input
    invalid_indices = isnan(values) | isnan(reference) | ...
                      abs(values - reference) > threshold;
    filtered(invalid_indices) = NaN; % Mark invalid entries as NaN
end

% I use this function in Arduino very often, so I put it here to be used in Matlab too.
function y = map_value(x, in_min, in_max, out_min, out_max)
    y = (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
end

% Helper function to load image paths from a folder
function image_paths = load_image_paths_from_folder(folder)
    extensions = {'.png', '.jpg', '.jpeg', '.bmp', '.gif'};
    image_paths = {};
    files = dir(folder);
    for i = 1:length(files)
        [~, ~, ext] = fileparts(files(i).name);
        if ismember(lower(ext), extensions)
            image_paths{end+1} = fullfile(folder, files(i).name);
        end
    end
end


function cropped_img = crop_image(image, center_x, center_y, width, height)
    % CROP_IMAGE Crops a specified rectangular region from an input image.
    %
    %   cropped_img = crop_image(image, center_x, center_y, width, height)
    %
    %   This function extracts a rectangular region from the input image
    %   based on the specified center coordinates and dimensions. The
    %   rectangle is defined by its center point (center_x, center_y) and
    %   its width and height. The function ensures that the rectangle is
    %   symmetrically centered around the given center point.
    %
    %   Input Arguments:
    %       image      - A 2D or 3D matrix representing the input image.
    %                    For grayscale images, this is a 2D matrix.
    %                    For RGB images, this is a 3D matrix.
    %       center_x   - The x-coordinate of the rectangle's center (horizontal axis).
    %       center_y   - The y-coordinate of the rectangle's center (vertical axis).
    %       width      - The width of the rectangle to be cropped.
    %       height     - The height of the rectangle to be cropped.
    %
    %   Output:
    %       cropped_img - The cropped region of the input image as a matrix.
    %                     The dimensions of the output matrix are determined
    %                     by the specified width and height.
    %
    %   Notes:
    %       - The function uses MATLAB's 1-based indexing.
    %       - If the specified rectangle extends beyond the boundaries of
    %         the input image, MATLAB will throw an indexing error.
    %       - Ensure that the input image has sufficient dimensions to
    %         accommodate the specified cropping region.
    %
    %   Example:
    %       % Load an image
    %       img = imread('example.jpg');
    %       
    %       % Define cropping parameters
    %       center_x = 100;
    %       center_y = 150;
    %       width = 50;
    %       height = 80;
    %       
    %       % Crop the image
    %       cropped_img = crop_image(img, center_x, center_y, width, height);
    %       
    %       % Display the cropped image
    %       imshow(cropped_img);
    left = round(center_x - width / 2);
    top = round(center_y - height / 2);
    right = round(center_x + width / 2);
    bottom = round(center_y + height / 2);
    cropped_img = image(top:bottom, left:right, :);
end


function nearest_position = find_nearest_position(P1, P2, R)
    % FIND_NEAREST_POSITION Finds the nearest position on a line segment to a reference point.
    %
    %   nearest_position = FIND_NEAREST_POSITION(P1, P2, R)
    %
    %   This function calculates the nearest position on the line segment
    %   defined by points P1 and P2 to a reference point R in 3D space.
    %
    %   Input:
    %       P1 - A 1x3 vector representing the first point of the line segment.
    %       P2 - A 1x3 vector representing the second point of the line segment.
    %       R  - A 1x3 vector representing the reference point.
    %
    %   Output:
    %       nearest_position - A 1x3 vector representing the nearest position
    %                          on the line segment to the reference point.
    %
    %   Example:
    %       P1 = [0, 0, 0];
    %       P2 = [1, 1, 1];
    %       R = [0.5, 0.5, 2];
    %       nearest_position = find_nearest_position(P1, P2, R);
    %       disp(nearest_position);

    % Compute the vector from P1 to P2 and from P1 to R
    v = P2 - P1; % Vector along the line segment
    w = R - P1;  % Vector from P1 to the reference point

    % Compute the scalar projection of w onto v
    t = dot(w, v) / dot(v, v);

    % Clamp t to the range [0, 1] to ensure the projection lies within the segment
    t_clamped = max(0, min(1, t));

    % Compute the nearest position on the line segment
    nearest_position = P1 + t_clamped * v;
end

function [distance, weight] = calculate_distance_and_weight(xyz_origin, points, degree)
    % CALCULATE_DISTANCE_AND_WEIGHT Calculates the distance and weight for a given degree.
    %
    %   [distance, weight] = CALCULATE_DISTANCE_AND_WEIGHT(xyz_origin, points, degree)
    %
    %   This function calculates the distance and weight for a given degree
    %   by finding the nearest point on the line segment between the two
    %   nearest points in the points array compared to the origin.
    %
    %   Input:
    %       xyz_origin - A 1x3 vector representing the origin point.
    %       points     - A Nx3 matrix representing the 3D points around the origin.
    %       degree     - A scalar value representing the degree (0 to 360).
    %
    %   Output:
    %       distance - The Euclidean distance from the origin to the nearest point.
    %       weight   - The interpolated z-axis value (weight) of the nearest point on the line segment.

end

function intersection_point = calculate_intersection(P1, P2, ref_point)
    % CALCULATE_INTERSECTION Finds the nearest point on the line segment (P1, P2) to ref_point.
    %
    %   intersection_point = CALCULATE_INTERSECTION(P1, P2, ref_point)
    %
    %   This function returns the point on the line segment between P1 and P2
    %   that is closest to ref_point (in 3D).
    %
    %   Input:
    %       P1 - 1x3 vector, start of line segment
    %       P2 - 1x3 vector, end of line segment
    %       ref_point - 1x3 vector, reference point
    %
    %   Output:
    %       intersection_point - 1x3 vector, closest point on the segment

    v = P2 - P1;
    w = ref_point - P1;
    t = dot(w, v) / dot(v, v);
    t_clamped = max(0, min(1, t));
    intersection_point = P1 + t_clamped * v;
end
