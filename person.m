classdef person < handle
    %person:
    %   A single individual  in the corporation.
    
    properties 
        unhappiness                % Between 0 and 1, varies with wage and other confounding factors
        stress                     % Between 0 and 1, varies with amount of work done
        quality                    % Between 0 and 1, unchanging parameter describes ability of individual
        experience                 % Increases over time, affects the efficiency of the worker
        wage                       % The salary of the individual in terms of sigma
    end
    
    methods
        function obj = person(unhappiness,stress,quality,experience,wage)
            obj.unhappiness = unhappiness;
            obj.stress = stress;
            obj.quality = quality;
            obj.experience = experience;
            obj.wage = wage;
        end
        
        function obj = meditate(obj, numFriends)
            % Equations describing the weekly change in a person's opinions
            % of themselves (interactions among quantities).
            % Calculate numFriends at the node level
            alpha = 0.05;
            beta  = 0.2;
            
            if numFriends == 0 % Oh, it's so lonely.
                % This variable makes not having friends take a steady
                %   stress toll.
                kroneckerDeltaNumFriends = 1;
            else
                kroneckerDeltaNumFriends = 0;
            end
            
            obj.stress = (99/100) * obj.stress + 0.05 * (1 - obj.stress)...
                ^(3/2) * kroneckerDeltaNumFriends;
            obj.unhappiness = (995/1000) * obj.unhappiness + alpha...
                * obj.stress * obj.unhappiness * (1 - obj.unhappiness)...
                * kroneckerDeltaNumFriends;
            obj.quality = obj.quality;
            obj.experience = obj.experience + beta * obj.quality...
                * (1 - obj.stress) * (1 - obj.unhappiness);
        end
        
        function deltaVector = interactWith(obj, friend, numFriends)
            % This returns a vector of changes in obj's quantities calculated
            %   from the interaction between obj and friend, to be added
            %   later (at the node level) to obj's quantities, after ALL
            %   interactions have been processed.
            
            alpha = 0.2 / (0.01 + numFriends);
            % Used to scale stress transfer based on importance of this
            % relationship.
            beta = 0.08 / (0.01 + numFriends);
            % Used to scale unhappiness transfer based on importance of
            % this relationship.
            gamma = 1 / (0.01 + sqrt(numFriends));
            % Used to scale experience transfer based on importance of this
            % relationship.
            
            deltaVector = [0, 0, 0, 0];
            % [unhappiness, stress, experience, wages]
            
            % unhappiness
            deltaVector(1) = beta * (friend.unhappiness - obj.unhappiness)...
                * obj.unhappiness * (1 - obj.unhappiness);
            % stress
            deltaVector(2) = alpha * (friend.stress - obj.stress)...
                * obj.stress * (1 - obj.stress);
            % experience
            deltaVector(3) = gamma * obj.quality * friend.quality...
                * (1 - obj.unhappiness) * (1 - friend.unhappiness)...
                * (friend.experience / (obj.experience + friend.experience));
        end
    end
    
end

