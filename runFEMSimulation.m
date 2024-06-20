function runFEMSimulation(meshFile, dt, mdiag_flag)
    if ~exist('log', 'dir')
        mkdir('log');
        mkdir('log/videos')
        mkdir('log/mat_files')
        disp(['Folder "l', 'log', '" created.']);
    end
    % Load mesh
    mesh = Mesh2D(meshFile);
    
    % Finite Element Mapping
    feMap = FEMap(mesh);
    
    % Parameters
    Tf = 35;
    a = 18.515;
    ft = 0.2383;
    fr = 0;
    fd = 1;
    Sigma_h = 9.5298e-4;
    
    % Initial condition
    u0 = zeros(mesh.numVertices, 1);
    initialNodes = (mesh.vertices(1, :) <= 0.1) & (mesh.vertices(2, :) >= 0.45) & (mesh.vertices(2, :) <= 0.55);
    u0(initialNodes) = 1;
    activationTime = Inf;
    
    % Time-stepping
    u = u0;
    numSteps = ceil(Tf / dt);
    
    % Plot the initial conditions
    figure(1);
    mesh.plotSolution(u0);
    view(2)
    title('Initial Condition');
    
    
    % Diffusivity for each element
    % Sigma_d = [10 * Sigma_h, Sigma_h, 0.1 * Sigma_h, Sigma_h]; % for different regions
    % Sigma_d = [Sigma_h, Sigma_h,Sigma_h,Sigma_h]; % homogeneous domain
    Sigma_d = [0.1 * Sigma_h,0.1 * Sigma_h,0.1 * Sigma_h,Sigma_h];
    diffusivity = Sigma_h * ones(mesh.numMeshElements, 1);
    diffusivity(mesh.meshElementFlags == 0) = Sigma_d(1); % Omega_d1
    diffusivity(mesh.meshElementFlags == 1) = Sigma_d(2); % Omega_d2
    diffusivity(mesh.meshElementFlags == 2) = Sigma_d(3); % Omega_d3
    diffusivity(mesh.meshElementFlags == 3) = Sigma_d(4); % Omega_h (healthy tissue)
    
    % Assemble stiffness matrix
    K = assembleDiffusion(mesh, feMap, diffusivity); % Assembled once, used in A
    
    % Assemble mass matrix
    M = assembleMass(mesh, feMap); % Assembled once, used in A
    if mdiag_flag
        M = diag(sum(M,2));
    end
    % Precompute the IMEX scheme matrix
    A = M + K*dt; % Precomputed matrix used in time-stepping loop
    
    % Initialize data storage
    data = struct();
    data.time = (0:numSteps) * dt;
    data.u = zeros(mesh.numVertices, numSteps + 1);
    data.u(:, 1) = u0;
    data.vertices = mesh.vertices;
    
    % Create a VideoWriter object for MP4 with dynamic filename
    [~, meshName, ~] = fileparts(meshFile); % Extract the mesh name from the file path
    videoFileName = sprintf('%s_dt%_without_diag.mp4', meshName, dt);
    videoFilePath = fullfile('log/videos', videoFileName);
    uDataFileName = sprintf('%s_dt%_without_diag.mat', meshName, dt);
    uDataFilePath = fullfile('log/mat_files', uDataFileName);
    v = VideoWriter(videoFilePath, 'MPEG-4');
    open(v);
    
    for n = 1:numSteps
        % Nonlinear reaction term (explicit part)
        f = a .* (u - fr) .* (u - ft) .* (u - fd); % Updated each step
    
        % Right-hand side
        rhs = M * u -  M * f * dt; % Computed using updated u and f
    
        % Solve the linear system (implicit part)
        unew = A \ rhs; % Solve using precomputed A
        u = unew;
    
        activated = all(u>ft);
        if activated == true && activationTime==Inf
            activationTime = n*dt;
        end
    
        % Check for NaN values
        if any(isnan(u))
            fprintf('NaN values detected at step %d\n', n);
            break;
        end
    
        if mod(n, 10) == 0
            figure(2)
            mesh.plotSolution(u);
            view(2)
            axis("tight")
            title(['Solution at time step ', num2str(n)]);
            drawnow
            frame = getframe(gcf);
            writeVideo(v, frame);
        end
    
        % Print intermediate values for debugging
        fprintf('Step %d, max u: %e, min u: %e\n', n, max(u), min(u));
    
        % Store the solution
        data.u(:, n + 1) = u;
    end
        
    
    % Plot the final solution
    figure(3)
    mesh.plotSolution(u);
    view(2)
    title('Final Solution');
    
    % Check if the potential remains between 0 and 1
    potentialValid = all(u >= 0 & u <= 1);
    
    % Display results
    fprintf('Results for mesh %s with dt = %f\n', meshFile, dt);
    fprintf('Potential within [0, 1]: %d\n', potentialValid);
    fprintf('Activation Time: %f\n', activationTime)
    
    % Save the data to a .mat file
    save(uDataFilePath, 'data');

    close(v);
end

