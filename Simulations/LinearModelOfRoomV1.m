function LinearModelOfRoomV1()
% Simulates a computer lab influenced by outdoor temp, number of people in
% room, equipment in the room, and the angle of a ar conditioning vent.
%
%  Chioma Shirley  and Aaron T. Becker, 10/20/2015
%    nschioma@uh.edu  for comments and questions
%
%  Get defendable values for G1, G2, G3, and G4
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

format compact
 t = 0:0.1:48; p = peopleInRoom(t); plot(t,p)

%%%% Setup constants for the model
tspan = [0,24*5] ;% in hours.
%initialCondition;
IC = outsideTemp(0);

% ODE 45 parameters
options = odeset('RelTol',1e-4,'AbsTol',1e-4);

%%%% Simulate the model  time is in hours
[time,TempIn] = ode45(@simRoom,tspan,IC,options);

%%%% Plot results.
figure(1)
clf
plot( time,TempIn, time,outsideTemp(time))
legend('indoor temp','outdoor temp')
xlabel('Time (hr)')
ylabel('Temp (Deg Celsius)')
title('Room temp as a function of time')

%plot the costs
figure(2)
clf
tempError = TempIn - desiredTemp(time, peopleInRoom(time));
tempErrorSq = tempError.^2;

controlEff = ProportionalTempControl(time, TempIn, peopleInRoom(time));

G5 = 100;  % coefficient to compare cost between control effort and temp error

plot(time, G5*cumsum(tempErrorSq), time, cumsum(controlEff));
legend('temp square error','control effort')
xlabel('Time (hr)')
ylabel('Cost')
title('Cumulative cost as a function of time')



    function Tout = outsideTemp(t)
        Tout = 85-15*cos((2*pi)/24*t);  %TODO: convert to Celsius
    end

    function PinRoom = peopleInRoom(hr)
        % model for number of people in room.  We will start with a deterministic equation, later we will use a probabilistic model
        % Dr. Driss on 10/16/2015 said there are 4 classes a day, 20 students in
        % each.  Assume classes are at 8--9:30, 10-11:30, 1-2:30, 3:4:30
        PinRoom = zeros(size(hr));
        PinRoom( 8 < hr & hr < 9.5) = 20;
        PinRoom( 10 < hr & hr < 11.5) = 20;
        PinRoom( 13 < hr & hr < 14.5) = 20;
        PinRoom( 15 < hr & hr < 16.5) = 20;
        
        %TEST  t = 0:0.1:48; p = peopleInRoom(t); plot(t,p)
        
    end

    function Tdes = desiredTemp(t,PinRoom) %#ok<INUSD>
            Tdes = 70;
    end

    function u = NoControl() %#ok<DEFNU>
        %No control
        u = 0;
    end


    function u = BangBangTempControl(t, Troom,PinRoom)
        %Bang Bang control
        tempBand =5;  %tempBand is maximum allowed deviation
        if Troom-tempBand > desiredTemp(t,PinRoom)
            u = 1;   % to do this right, we need to use event condiitons.  Look at BALLODE demo
        else
            u = 0;
        end
    end

    function u = ProportionalTempControl(t, Troom,PinRoom)
        Kp =10;  %Proportional Gain
        u = Kp*(Troom - desiredTemp(t,PinRoom)) ;   % to do this right, we need to use event condiitons.  Look at BALLODE demo
        % limit the control effort
        u = min(1,max(0,u));
    end




%%% Differential Equation Simulation
    function dTroom = simRoom(t,Troom)
        % t is the time in seconds
        % Troom = temperature of the room.
        % dTroom is the change in temperature  (the derivative)
        Tout = outsideTemp(t);
        PinRoom = peopleInRoom(t);
        ComputerInRoom = 20;
        % TODO: give reasonable values
        G1 = 0.1;   % coefficient for change in temp due to outside-inside temp
        G2 =  0.01; % coefficient for change in temp due one person
        G3 = 0.001; % coefficient for change in temp due one computer
        G4 = 5;  % % coefficient for change in temp due to fraction of air conditioning vent (from 0 to 1)
        
        %%%%%%%% CONTROLLERS
        %%% 0. no control
        % u = NoControl()
        %%% 1. Bang Bang control
        %u = BangBangTempControl(t, Troom,PinRoom); %TODO: use events
        %%% 2. Proportional Control
        u = ProportionalTempControl(t, Troom,PinRoom);
        %%% 3. PID
        
        %%% 4. Feedforward Control
        
        
        
        
        dTroom = G1*(Tout-Troom) + G2*PinRoom + G3*ComputerInRoom - G4*u;
    end

end
