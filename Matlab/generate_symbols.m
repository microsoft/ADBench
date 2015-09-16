function symbols_map = generate_symbols()
    
symbols_map = containers.Map;
symbols_map('') = 'none';
symbols_map('eigen') = '^';
symbols_map('vector') = 'v';
symbols_map('split') = 'x';
symbols_map('eigen_vector') = 'diamond';
symbols_map('automode') = 'o';
symbols_map('sparse') = '>';
symbols_map('eigen_sparse') = 'diamond';
symbols_map('light') = '<';
symbols_map('light_tapeless') = '*';
symbols_map('eigen_tapeless') = 'diamond';

end