classdef sys3lab_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        psk_legend               matlab.ui.control.CheckBox
        carrier_legend           matlab.ui.control.CheckBox
        bits_legend              matlab.ui.control.CheckBox
        space_const              matlab.ui.control.Button
        time_plots               matlab.ui.control.Button
        freqScale                matlab.ui.control.DropDown
        cFreq                    matlab.ui.control.Slider
        CarrierfreqLabel         matlab.ui.control.Label
        bitstream_edit           matlab.ui.control.EditField
        BitstreamEditFieldLabel  matlab.ui.control.Label
        UIAxes                   matlab.ui.control.UIAxes
    end

    
    properties (Access = public)
        bbplot matlab.graphics.chart.primitive.Line
        cplot matlab.graphics.chart.primitive.Line
        modplot matlab.graphics.chart.primitive.Line
    end

    methods (Access = private)
        function generate_psk(app, bitstream, fc, scale)
            n = length(bitstream);
            t = 0:0.01:n;
            x = 1:1:(n+1)*100; % reserves 100 spaces ber pit for visual representation 
            for i = 1:n
                % convert bits to bipolar form
                if (bitstream(i) == 0)
                    b_p(i) = -1;
                else
                    b_p(i) = 1;
                end
                % create baseband waveform from bipolar form
                for j = i:0.1:i+1
                    bw(x(i*100:(i+1)*100)) = b_p(i);
                end
            end
            bw = bw(100:end);   % baseband waveform
            sint = sin(2*pi*fc*scale*linspace(0, n, length(bw)));    % carrier signal
            st = bw.*sint;  % modulated signal

            % clear previous plot
            cla(app.UIAxes);

            % Plot the data
            hold(app.UIAxes, 'on');
            app.bbplot = plot(app.UIAxes, t, bw, '--k', 'LineWidth', 0.5);
            app.cplot = plot(app.UIAxes, t, sint, '-g', 'LineWidth', 1);
            app.modplot = plot(app.UIAxes, t, st, '-b', 'LineWidth', 2);
            title(app.UIAxes,'PSK waveform');
            xlabel(app.UIAxes,'time');
            ylabel(app.UIAxes,'signal');
            grid(app.UIAxes, 'on');
            axis(app.UIAxes,[0 n -2 2])
            legend(app.UIAxes, 'baseband waveform', 'sinusodial carrier', 'psk modulated signal');

        end


    end


    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: time_plots
        function time_plotsButtonPushed(app, event)
            % Read bitstream data:
            bitstream_txt = app.bitstream_edit.Value;
            bitstream_digits = split(bitstream_txt, ' ');
            bitstream = str2double(bitstream_digits);
            fc = app.cFreq.Value;

            dropdownValues = struct('Hz', 1, 'KHz', 1e3, 'MHz', 1e6, 'GHz', 1e9); % mapping dropdown list to their corresponding values
            selectedScale = app.freqScale.Value;
            scale = dropdownValues.(selectedScale);
            generate_psk(app, bitstream, fc, scale);
        end

        % Value changed function: bits_legend
        function bits_legendValueChanged(app, event)
            cb1value = event.Value;
            if cb1value
                app.bbplot.Visible = 'on';
            else
                app.bbplot.Visible = 'off';
            end
        end

        % Value changed function: carrier_legend
        function carrier_legendValueChanged(app, event)
            cb2value = event.Value;
            if cb2value
                app.cplot.Visible = 'on';
            else
                app.cplot.Visible = 'off';
            end
        end

        % Value changed function: psk_legend
        function psk_legendValueChanged(app, event)
            cb3value = event.Value;
            if cb3value
                app.modplot.Visible = 'on';
            else
                app.modplot.Visible = 'off';
            end
        end

        % Button pushed function: space_const
        function space_constButtonPushed(app, event)
            % Read bitstream data:
            bitstream_txt = app.bitstream_edit.Value;
            bitstream_digits = split(bitstream_txt, ' ');
            bitstream = str2double(bitstream_digits);

            % Modulate the input bit sequence using PSK
            txSig = pskmod(bitstream,2);

            % Add noise to the signal
            SNRdB = 10; % Signal-to-Noise Ratio in dB
            rxSig = awgn(txSig,SNRdB);

            % clear previous plot
            cla(app.UIAxes);

            % Plot the data
            hold(app.UIAxes, 'on');
            plot(app.UIAxes, real(txSig), imag(txSig), 'o');
            plot(app.UIAxes,real(rxSig), imag(rxSig), 'x');
            title(app.UIAxes,'PSK Signal Constellation Diagram');
            xlabel(app.UIAxes,'I Component');
            ylabel(app.UIAxes,'Q Component');
            grid(app.UIAxes, 'on');
            axis(app.UIAxes,[-2 2 -2 2])
            legend(app.UIAxes, 'Transmitted Signal', 'Recieved Signal');
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 647 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'PSK waveform')
            xlabel(app.UIAxes, 'time')
            ylabel(app.UIAxes, 'signal')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [9 192 640 280];

            % Create BitstreamEditFieldLabel
            app.BitstreamEditFieldLabel = uilabel(app.UIFigure);
            app.BitstreamEditFieldLabel.HorizontalAlignment = 'right';
            app.BitstreamEditFieldLabel.Position = [8 117 62 22];
            app.BitstreamEditFieldLabel.Text = 'Bit stream:';

            % Create bitstream_edit
            app.bitstream_edit = uieditfield(app.UIFigure, 'text');
            app.bitstream_edit.Position = [90 117 544 22];

            % Create CarrierfreqLabel
            app.CarrierfreqLabel = uilabel(app.UIFigure);
            app.CarrierfreqLabel.HorizontalAlignment = 'right';
            app.CarrierfreqLabel.Position = [8 82 69 22];
            app.CarrierfreqLabel.Text = 'Carrier freq:';

            % Create cFreq
            app.cFreq = uislider(app.UIFigure);
            app.cFreq.Position = [90 92 435 3];

            % Create freqScale
            app.freqScale = uidropdown(app.UIFigure);
            app.freqScale.Items = {'Hz', 'KHz', 'MHz', 'GHz'};
            app.freqScale.Position = [542 82 92 22];
            app.freqScale.Value = 'Hz';

            % Create time_plots
            app.time_plots = uibutton(app.UIFigure, 'push');
            app.time_plots.ButtonPushedFcn = createCallbackFcn(app, @time_plotsButtonPushed, true);
            app.time_plots.Position = [128 25 164 23];
            app.time_plots.Text = 'Time domain representation';

            % Create space_const
            app.space_const = uibutton(app.UIFigure, 'push');
            app.space_const.ButtonPushedFcn = createCallbackFcn(app, @space_constButtonPushed, true);
            app.space_const.Position = [378 25 164 23];
            app.space_const.Text = 'Space Constellation';

            % Create bits_legend
            app.bits_legend = uicheckbox(app.UIFigure);
            app.bits_legend.ValueChangedFcn = createCallbackFcn(app, @bits_legendValueChanged, true);
            app.bits_legend.Tag = 'cb1';
            app.bits_legend.Text = 'Baseband waveform';
            app.bits_legend.Position = [129 163 131 22];
            app.bits_legend.Value = true;

            % Create carrier_legend
            app.carrier_legend = uicheckbox(app.UIFigure);
            app.carrier_legend.ValueChangedFcn = createCallbackFcn(app, @carrier_legendValueChanged, true);
            app.carrier_legend.Tag = 'cb2';
            app.carrier_legend.Text = 'Carrier signal';
            app.carrier_legend.Position = [283 163 93 22];
            app.carrier_legend.Value = true;

            % Create psk_legend
            app.psk_legend = uicheckbox(app.UIFigure);
            app.psk_legend.ValueChangedFcn = createCallbackFcn(app, @psk_legendValueChanged, true);
            app.psk_legend.Tag = 'cb3';
            app.psk_legend.Text = 'PSK waveform';
            app.psk_legend.Position = [410 163 101 22];
            app.psk_legend.Value = true;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = sys3lab_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end