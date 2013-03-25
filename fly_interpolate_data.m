%{
    Author - Satmeet Ubhi
    This file corrects the ctrax mat file by comparing it with
    the ground truth file
%}

%constant for devlopment
function trx = fly_assignment()

    get_data = 1;
    MAX_INTERPOLATE = 10;
    global trx_data;

    if(get_data == 1)

        [fileName,pathName] = uigetfile('*.xls','Select the Ground Truth file');
        pathto_gt_file = [pathName,fileName];

        %get column index for ground truth table inside the xls.
        prompt = {'Ground truth index, e.g. A2:H21   __________________________', ...
                    'Worksheet name'
                };
        uanswer  = inputdlg(prompt, 'Please enter CTRAX truth data range', 1);
        data_range_gt = cell2mat(uanswer(1));
        worksheet_name = cell2mat(uanswer(2));

        % load ctrax file here
        [fileName,pathName] = uigetfile('*.mat','Select the Ctrax MAT file');
        pathto_trx_file = [pathName,fileName];

    else
        pathto_gt_file = 'D:\matlab-work\fly-assignment\MatFix Flycheck3b.xls';
        data_range_gt = 'A2:H21';
        worksheet_name = 'cam25.1';
        pathto_trx_file = 'converted_fixed_ MAT_BMAA090924_CAM25_DAY1.mat';
    end
    gtruth_data = xlsread(pathto_gt_file,  worksheet_name, data_range_gt);    
    trx_data = load(pathto_trx_file);


    % ask user to input the data range for each fly.
    num_of_treats = unique(gtruth_data(:,4));
    size_num_treats = length(num_of_treats);
    mat_fly_file = struct([]);
    for i=1:size_num_treats

       treat = num_of_treats(i);
       %Load the data from the XLS file, for each fly (prompt for range)
       prompt_str = strcat('Fly with treat = ', num2str(treat), ...
                ' e.g. L2:N25 ___________________________');
       prompt = {prompt_str };
       uanswer  = inputdlg(prompt, 'Please enter data range for fly', 1);
       data_range_gt = cell2mat(uanswer(1));

       [treat_data, treat_str_data] = xlsread(pathto_gt_file,...
           worksheet_name, data_range_gt);

       len = length(mat_fly_file);
       mat_fly_file(len+1).trx = process_data(treat_data, trx_data);
       mat_fly_file(len+1).treat = num2str(treat);
    end
    
%     trx = mat_fly_file;
  trx = interpolate_fix_data(mat_fly_file, MAX_INTERPOLATE);  
end

function mat_fly_file = process_data(treat_data, trx_data)

    trx_fly_data = [];
    res_data = get_numof_flies_in_treat(treat_data);
    for num = 1:length(res_data)
        % copy for fly (num), from row res_data(num,2) to res_data(num,3)
        % values from ~Frame num~ treat_data(res_data(num,2),2)
        % ~fly num~ treat_data(res_data(num,3),3)
        fprintf('Copy for fly %d from row %d to row %d \n',...
            num, res_data(num,2), res_data(num,3));
        start_loop = res_data(num,2);
        
        if (start_loop == 0)
            start_loop = 1;
        end

        loop = start_loop;
        while loop <= res_data(num,3)
            if(((loop +1) <= length(treat_data)))
                % Compare fly numbers
                if(treat_data(loop,3) == treat_data(loop +1,3))
                    fprintf('\t For fly %d, frame %d to frame %d belongs to fly %d \n',...
                        num, treat_data(loop,2), treat_data(loop+1,2), treat_data(loop,3));
                    %copy fly info
                    trx_fly_data = copy_fly_info(trx_data, trx_fly_data, treat_data(loop,3), num,...
                        treat_data(loop,2), treat_data(loop+1,2));
                    loop = loop + 2;   
                else
                    fprintf('\t For fly %d, frame %d belongs to fly %d \n', num, ...
                        treat_data(loop,2), treat_data(loop,3));
                    % Copy the fly info
                    trx_fly_data = copy_fly_info(trx_data, trx_fly_data ,treat_data(loop,3), num,...
                        treat_data(loop,2), treat_data(loop,2));
                    loop = loop + 1;
                    fprintf('\nDONE---------\n');
                end
            else
                break;
            end
        end
        
    end
      
    mat_fly_file = trx_fly_data;

end

function trx = copy_fly_info(trx_data, trxin, flyidfrom, flyidto, framefrom, frameto)
    if( ~isnan(flyidfrom))
        trxin.trx(flyidto).x(framefrom:frameto) = trx_data.trx(flyidfrom).x(framefrom:frameto);
        trxin.trx(flyidto).y(framefrom:frameto) = trx_data.trx(flyidfrom).y(framefrom:frameto);
        trxin.trx(flyidto).theta(framefrom:frameto) = trx_data.trx(flyidfrom).theta(framefrom:frameto);
        trxin.trx(flyidto).a(framefrom:frameto) = trx_data.trx(flyidfrom).a(framefrom:frameto);
        trxin.trx(flyidto).b(framefrom:frameto) = trx_data.trx(flyidfrom).b(framefrom:frameto);
        trxin.trx(flyidto).x_mm(framefrom:frameto) = trx_data.trx(flyidfrom).x_mm(framefrom:frameto);
        trxin.trx(flyidto).y_mm(framefrom:frameto) = trx_data.trx(flyidfrom).y_mm(framefrom:frameto);
        trxin.trx(flyidto).a_mm(framefrom:frameto) = trx_data.trx(flyidfrom).a_mm(framefrom:frameto);
        trxin.trx(flyidto).b_mm(framefrom:frameto) = trx_data.trx(flyidfrom).b_mm(framefrom:frameto);
        trxin.trx(flyidto).id = trx_data.trx(flyidfrom).id;
        trxin.trx(flyidto).moviename = trx_data.trx(flyidfrom).moviename;
        trxin.trx(flyidto).firstframe = trx_data.trx(flyidfrom).firstframe;
        trxin.trx(flyidto).arena = trx_data.trx(flyidfrom).arena;
        trxin.trx(flyidto).nframes = trx_data.trx(flyidfrom).nframes;
        trxin.trx(flyidto).endframe = trx_data.trx(flyidfrom).endframe;
        trxin.trx(flyidto).matname = trx_data.trx(flyidfrom).matname;
    else
        if(isnan(frameto))
            frameto = framefrom;
        end
        trxin.trx(flyidto).x(framefrom:frameto) = 999;
        trxin.trx(flyidto).y(framefrom:frameto) = 999;
        trxin.trx(flyidto).theta(framefrom:frameto) = 999;
        trxin.trx(flyidto).a(framefrom:frameto) = 999;
        trxin.trx(flyidto).b(framefrom:frameto) = 999;
        trxin.trx(flyidto).x_mm(framefrom:frameto) = 999;
        trxin.trx(flyidto).y_mm(framefrom:frameto) = 999;
        trxin.trx(flyidto).a_mm(framefrom:frameto) = 999;
        trxin.trx(flyidto).b_mm(framefrom:frameto) = 999;
    end
    trx = trxin;
end

function res = get_numof_flies_in_treat(treat_data)

    % Number of flies is determined by looking at the row of treat_data...
    % where all the entries are empty or NaN
    last_row_empty = 0;
    num =1;
    [rows,cols] = size(treat_data);
    for i=1:rows
%         fprintf('Start range for fly %d is %d', num, i);
        if(sum(~isnan(treat_data(i,:))) == 0)
            if(last_row_empty == 0)
                last_row_empty = 1;
                num = num + 1;
            end
        else
            if(last_row_empty == 1)
                res(num,2) = i;
            end
            last_row_empty = 0;
        end
        res(num,1) = num;
        res(num,3) = i;

    end
     
end

function trx = interpolate_fix_data(tdata, MAX_INTERPOLATE)
	len = length(tdata);
    trx = struct([]);
%   Prepare data structure as Ctrax 
    for i = 1:len
        for j = 1 : length(tdata(i).trx.trx)
            tsize = length(trx);
            trx(tsize+1).trx = tdata(i).trx.trx(j);
            trx(tsize+1).trx.treat = tdata(i).treat;
        end
    end
    
%   Interpolate missing data
    len = length(trx);
    bpt= 0;     bpt2= 0;
    i =1;
    eloop = length(trx(i).trx.x);
    for loop = 1 : eloop
        if( trx(i).trx.x(loop) == 999)
            bpt = loop;
            break;
        end
    end
    if(bpt ~= 0)
        for loop2 = bpt+1: eloop
            if (trx(i).trx.x(loop2) ~= 0)
                bpt2 = loop2 - 1;
                break;
            end
        end
    end
    if (bpt2 - bpt) > MAX_INTERPOLATE
        trx(i).trx.x(bpt:bpt2) = 999;
        trx(i).trx.y(bpt:bpt2) = 999;
        trx(i).trx.theta(bpt:bpt2) = 999;
        trx(i).trx.a(bpt:bpt2) = 999;
        trx(i).trx.b(bpt:bpt2) = 999;
        trx(i).trx.x_mm(bpt:bpt2) = 999;
        trx(i).trx.y_mm(bpt:bpt2) = 999;
        trx(i).trx.a_mm(bpt:bpt2) = 999;
        trx(i).trx.b_mm(bpt:bpt2) = 999;        
    else
        %do interpolate
        for j = bpt:bpt2
           trx(i).trx.x(j) = do_interpolate(j,bpt-1,bpt2+1,trx(i).trx.x(bpt-1),trx(i).trx.x(bpt2+1));
           trx(i).trx.y(j) = do_interpolate(j,bpt-1,bpt2+1,trx(i).trx.y(bpt-1),trx(i).trx.y(bpt2+1));
           trx(i).trx.theta(j) = do_interpolate(j,bpt-1,bpt2+1,trx(i).trx.theta(bpt-1),trx(i).trx.theta(bpt2+1));
           trx(i).trx.a(j) = do_interpolate(j,bpt-1,bpt2+1,trx(i).trx.a(bpt-1),trx(i).trx.x(bpt2+1));
           trx(i).trx.b(j) = do_interpolate(j,bpt-1,bpt2+1,trx(i).trx.b(bpt-1),trx(i).trx.x(bpt2+1));
           trx(i).trx.x_mm(j) = do_interpolate(j,bpt-1,bpt2+1,trx(i).trx.x_mm(bpt-1),trx(i).trx.x_mm(bpt2+1));           
           trx(i).trx.y_mm(j) = do_interpolate(j,bpt-1,bpt2+1,trx(i).trx.y_mm(bpt-1),trx(i).trx.y_mm(bpt2+1));
           trx(i).trx.a_mm(j) = do_interpolate(j,bpt-1,bpt2+1,trx(i).trx.a_mm(bpt-1),trx(i).trx.a_mm(bpt2+1));                      
           trx(i).trx.b_mm(j) = do_interpolate(j,bpt-1,bpt2+1,trx(i).trx.b_mm(bpt-1),trx(i).trx.b_mm(bpt2+1));                      
        end
    end
end

function y = do_interpolate(x,xa,xb,ya,yb)
    y = ya + (x-xa)*(yb-ya)/(xb-xa);
end
